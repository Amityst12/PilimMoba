class_name JungleMonster
extends Entity
## Neutral jungle camp monsters (Blue Golem, Red Bramble, and Rift Behemoth Boss).
##
## Stays dormant in its camp pit until attacked by a champion. Pursues the attacker
## within leash range. If pulled too far, resets, runs home and regenerates to 100% HP.
## Slaying camps awards powerful buffs and team gold.

enum MonsterType { BLUE_GOLEM, RED_BRAMBLE, RIFT_BEHEMOTH }

var monster_type: MonsterType = MonsterType.BLUE_GOLEM
var spawn_origin: Vector3 = Vector3.ZERO
var leash_radius: float = 12.0
var aggro_target_id: int = -1
var is_resetting: bool = false
var respawn_timer: float = 0.0
var respawn_interval: float = 90.0
var gold_value: int = 110
var xp_value: float = 150.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D


func _ready() -> void:
	team = GameConst.TEAM_NONE
	bar_height = 2.8 if monster_type != MonsterType.RIFT_BEHEMOTH else 4.2
	radius = 0.8 if monster_type != MonsterType.RIFT_BEHEMOTH else 1.6
	mobile = true
	if multiplayer.is_server():
		spawn_origin = global_position
		_setup_monster_stats()
	_build_visuals()
	super._ready()


func _setup_monster_stats() -> void:
	match monster_type:
		MonsterType.BLUE_GOLEM:
			max_health = 1400.0
			health = max_health
			attack_damage = 38.0
			armor = 20.0
			magic_resist = 20.0
			base_attack_speed = 0.7
			base_move_speed = 4.2
			gold_value = 110
			xp_value = 160.0
			respawn_interval = 90.0
		MonsterType.RED_BRAMBLE:
			max_health = 1400.0
			health = max_health
			attack_damage = 44.0
			armor = 25.0
			magic_resist = 15.0
			base_attack_speed = 0.65
			base_move_speed = 4.2
			gold_value = 110
			xp_value = 160.0
			respawn_interval = 90.0
		MonsterType.RIFT_BEHEMOTH:
			max_health = 4200.0
			health = max_health
			attack_damage = 75.0
			armor = 40.0
			magic_resist = 40.0
			base_attack_speed = 0.8
			base_move_speed = 4.6
			leash_radius = 16.0
			gold_value = 300
			xp_value = 450.0
			respawn_interval = 180.0


func _build_visuals() -> void:
	if visual == null or DisplayServer.get_name() == "headless":
		return

	# Color and scale based on monster type
	var color: Color
	var scale_factor := 1.0
	match monster_type:
		MonsterType.BLUE_GOLEM:
			color = Color(0.2, 0.65, 1.0)
			scale_factor = 1.1
		MonsterType.RED_BRAMBLE:
			color = Color(1.0, 0.35, 0.15)
			scale_factor = 1.1
		MonsterType.RIFT_BEHEMOTH:
			color = Color(0.85, 0.25, 0.95)
			scale_factor = 1.8

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color.darkened(0.2)
	mat.roughness = 0.6
	mat.emission_enabled = true
	mat.emission = color * 0.45

	var body := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.7 * scale_factor
	sphere.height = 1.4 * scale_factor
	body.mesh = sphere
	body.material_override = mat
	body.position.y = 0.7 * scale_factor
	visual.add_child(body)

	# Glowing core
	var core := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 0.4 * scale_factor
	core.mesh = box
	var core_mat := StandardMaterial3D.new()
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_mat.albedo_color = color.lightened(0.5)
	core.material_override = core_mat
	core.position = Vector3(0.0, 0.8 * scale_factor, 0.3 * scale_factor)
	visual.add_child(core)


func _server_tick(delta: float, now: float) -> void:
	if is_resetting:
		_process_leash_reset(delta)
		return

	# Leash check: pulled too far from camp
	if global_position.distance_to(spawn_origin) > leash_radius:
		_start_leash_reset()
		return

	if aggro_target_id != -1:
		var target: Entity = Game.current.get_entity(aggro_target_id) if Game.current else null
		if target == null or target.dead or target.planar_distance_to_point(global_position) > leash_radius + 4.0:
			aggro_target_id = -1
			velocity = Vector3.ZERO
			return

		var dist: float = edge_distance_to(target)
		if dist <= attack_range + 0.3:
			velocity = Vector3.ZERO
			face_point(target.global_position)
			if can_start_attack(now):
				begin_attack(target, now)
		else:
			face_point(target.global_position)
			var dir := (target.global_position - global_position).normalized()
			dir.y = 0.0
			velocity = dir * get_move_speed()
			move_and_slide()
	else:
		# Slowly drift back to camp origin if not exactly at center
		if global_position.distance_to(spawn_origin) > 0.4:
			var dir := (spawn_origin - global_position).normalized()
			dir.y = 0.0
			velocity = dir * (get_move_speed() * 0.6)
			move_and_slide()
		else:
			velocity = Vector3.ZERO


func _modify_incoming_damage(amount: float, source: Entity, _damage_type: int) -> float:
	if is_resetting:
		return 0.0
	# Aggro on first champion that hits us
	if source is Champion and aggro_target_id == -1:
		aggro_target_id = source.net_id
	return amount


func _start_leash_reset() -> void:
	is_resetting = true
	aggro_target_id = -1
	cancel_attack_windup()


func _process_leash_reset(delta: float) -> void:
	heal(max_health * 0.3 * delta)
	var dir := (spawn_origin - global_position)
	dir.y = 0.0
	if dir.length() <= 0.4:
		global_position = spawn_origin
		velocity = Vector3.ZERO
		health = max_health
		is_resetting = false
	else:
		face_point(spawn_origin)
		velocity = dir.normalized() * (get_move_speed() * 1.5)
		move_and_slide()


func _on_death(killer: Entity) -> void:
	var killer_champ: Champion = killer as Champion
	if killer_champ == null and Game.current and aggro_target_id != -1:
		killer_champ = Game.current.get_entity(aggro_target_id) as Champion

	if killer_champ:
		killer_champ.add_gold(gold_value)
		killer_champ.add_xp(xp_value)
		killer_champ.creep_score += 1

		# Award specific camp buff
		match monster_type:
			MonsterType.BLUE_GOLEM:
				killer_champ.apply_status(GameConst.Status.BLUE_BUFF, 0.0, 90.0, killer_champ, &"blue_buff")
				killer_champ.mana = minf(killer_champ.max_mana, killer_champ.mana + 150.0)
				Game.current.play_fx("levelup", killer_champ.global_position, {"color": Color(0.2, 0.7, 1.0)})
				Game.current.announce("%s secured the Crest of Insight (Blue Buff)!" % killer_champ.player_name, Color(0.3, 0.7, 1.0), false)
			MonsterType.RED_BRAMBLE:
				killer_champ.apply_status(GameConst.Status.RED_BUFF, 24.0, 90.0, killer_champ, &"red_buff")
				killer_champ.heal(150.0)
				Game.current.play_fx("levelup", killer_champ.global_position, {"color": Color(1.0, 0.4, 0.2)})
				Game.current.announce("%s secured the Crest of Cinders (Red Buff)!" % killer_champ.player_name, Color(1.0, 0.4, 0.2), false)
			MonsterType.RIFT_BEHEMOTH:
				# Team-wide buff and 300 gold to every living ally!
				for c: Champion in Game.current.champions:
					if c.team == killer_champ.team:
						c.add_gold(300)
						if not c.dead:
							c.apply_status(GameConst.Status.BOSS_BUFF, 0.15, 120.0, c, &"boss_buff")
							Game.current.play_fx("levelup", c.global_position, {"color": Color(0.9, 0.3, 1.0)})
				var team_name: String = "Blue Team" if killer_champ.team == GameConst.TEAM_BLUE else "Red Team"
				Game.current.announce("%s has slain the Rift Behemoth!" % team_name, Color(0.95, 0.75, 0.2), true)


func get_kind() -> Kind:
	return Kind.MINION
