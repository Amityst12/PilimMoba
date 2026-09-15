class_name Entity
extends CharacterBody3D
## Base class for every networked gameplay object (champions, minions, towers, nexus).
##
## Authority model: the server (peer 1) simulates everything in `_server_tick`.
## Clients only receive replicated state through the MultiplayerSynchronizer in the
## entity scene and smoothly interpolate towards it.

signal damaged(amount: float, source: Entity)
signal died(killer: Entity)

enum Kind { CHAMPION, MINION, TOWER, NEXUS }

## Gameplay collision radius (all gameplay hit tests are 2D circles on the XZ plane).
@export var radius: float = 0.5
## Height of the overhead health bar above the entity origin.
@export var bar_height: float = 2.4
@export var mobile: bool = true
## Style id of the basic-attack projectile. Empty = melee.
@export var attack_projectile_style: StringName = &""
@export var attack_projectile_speed: float = 20.0
## Fraction of the attack period spent winding up before the hit lands / projectile fires.
@export var attack_windup_ratio: float = 0.3

# --- Replicated state ----------------------------------------------------------
var net_id: int = 0
var team: int = GameConst.TEAM_NONE
var net_position: Vector3 = Vector3.ZERO
var net_velocity: Vector3 = Vector3.ZERO
var net_yaw: float = 0.0
var health: float = 100.0
var max_health: float = 100.0
var shield: float = 0.0
var status_flags: int = 0
var attack_seq: int = 0:
	set(value):
		if value != attack_seq:
			attack_seq = value
			if is_inside_tree() and not multiplayer.is_server():
				_play_attack_animation()
var dead: bool = false:
	set(value):
		if value != dead:
			dead = value
			if is_inside_tree():
				_on_dead_changed()

# --- Server-side stats ---------------------------------------------------------
var armor: float = 0.0
var magic_resist: float = 0.0
var attack_damage: float = 0.0
var ability_power: float = 0.0
var base_attack_speed: float = 1.0
var attack_range: float = 1.5
var base_move_speed: float = 5.0
var health_regen: float = 0.0
var statuses: StatusController = StatusController.new()

# --- Server-side attack state --------------------------------------------------
var _attack_ready_at: float = 0.0
var _windup_end: float = -1.0
var _windup_target_id: int = -1

# --- Client-side presentation ---------------------------------------------------
var _since_sync: float = 0.0
var _flash_left: float = 0.0
var _lunge: float = 0.0
var _death_anim: float = 0.0

@onready var visual: Node3D = get_node_or_null("Visual") as Node3D
@onready var synchronizer: MultiplayerSynchronizer = get_node_or_null("Sync") as MultiplayerSynchronizer

static var _flash_material: StandardMaterial3D


func _ready() -> void:
	collision_layer = GameConst.LAYER_UNITS if mobile else GameConst.LAYER_WORLD
	collision_mask = GameConst.LAYER_WORLD if mobile else 0
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	if multiplayer.is_server():
		net_position = global_position
	else:
		global_position = net_position
		if synchronizer:
			synchronizer.synchronized.connect(_on_synchronized)
	if visual:
		visual.rotation.y = net_yaw
	if Game.current:
		Game.current.register_entity(self)
	_on_dead_changed()


func _exit_tree() -> void:
	if Game.current:
		Game.current.unregister_entity(self)


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	var game := Game.current
	if game == null or not game.is_playing():
		return
	statuses.tick(delta)
	if not dead:
		_server_tick(delta, game.game_time)
	shield = statuses.shield
	status_flags = statuses.flags() | _extra_status_flags()
	net_position = global_position
	net_velocity = velocity
	if visual:
		net_yaw = visual.rotation.y


func _process(delta: float) -> void:
	if not multiplayer.is_server() and mobile:
		_since_sync += delta
		var target: Vector3 = net_position + net_velocity * minf(_since_sync, 0.12)
		if global_position.distance_squared_to(target) > 16.0:
			global_position = target
		else:
			global_position = global_position.lerp(target, 1.0 - exp(-delta * 18.0))
		if visual:
			visual.rotation.y = lerp_angle(visual.rotation.y, net_yaw, 1.0 - exp(-delta * 14.0))
	_update_presentation(delta)


func _on_synchronized() -> void:
	_since_sync = 0.0


# --- Virtual hooks ------------------------------------------------------------------

func get_kind() -> Kind:
	return Kind.MINION


func get_display_name() -> String:
	return name


## Server simulation step (only called while alive and the match is running).
func _server_tick(_delta: float, _now: float) -> void:
	pass


func _extra_status_flags() -> int:
	return 0


## Structures override this to implement tower protection.
func is_vulnerable() -> bool:
	return true


func _modify_incoming_damage(amount: float, _source: Entity, _damage_type: int) -> float:
	return amount


func _on_took_damage(_amount: float, _source: Entity, _damage_type: int, _is_ability: bool) -> void:
	pass


func _on_death(_killer: Entity) -> void:
	pass


func _on_stunned() -> void:
	pass


# --- Queries ----------------------------------------------------------------------

func is_alive() -> bool:
	return not dead and is_inside_tree()


func is_structure() -> bool:
	var k: Kind = get_kind()
	return k == Kind.TOWER or k == Kind.NEXUS


func is_targetable_by(other_team: int) -> bool:
	return (not dead and team != other_team and (status_flags & GameConst.FLAG_UNTARGETABLE) == 0
			and is_vulnerable())


func flat_position() -> Vector3:
	var p: Vector3 = global_position
	p.y = 0.0
	return p


func planar_distance_to_point(point: Vector3) -> float:
	return Vector2(global_position.x - point.x, global_position.z - point.z).length()


## Distance between the edges of the two gameplay circles.
func edge_distance_to(other: Entity) -> float:
	return planar_distance_to_point(other.global_position) - radius - other.radius


func get_attack_speed() -> float:
	return clampf(base_attack_speed * (1.0 + statuses.attack_speed_bonus), 0.2, 2.5)


func get_move_speed() -> float:
	return maxf(1.0, base_move_speed * statuses.move_multiplier)


func health_fraction() -> float:
	return health / max_health if max_health > 0.0 else 0.0


# --- Server combat API --------------------------------------------------------------

## Deals damage (server only). Returns the mitigated damage dealt (including shield absorption).
func take_damage(amount: float, damage_type: int, source: Entity, is_ability: bool = false) -> float:
	if not multiplayer.is_server() or dead or amount <= 0.0:
		return 0.0
	var dealt: float = amount
	match damage_type:
		GameConst.DamageType.PHYSICAL:
			dealt = GameConst.mitigate(amount, armor)
		GameConst.DamageType.MAGIC:
			dealt = GameConst.mitigate(amount, magic_resist)
	dealt = _modify_incoming_damage(dealt, source, damage_type)
	if dealt <= 0.0:
		return 0.0
	var through: float = statuses.absorb_damage(dealt)
	shield = statuses.shield
	health = maxf(0.0, health - through)
	_on_took_damage(dealt, source, damage_type, is_ability)
	damaged.emit(dealt, source)
	if Game.current:
		Game.current.on_damage_dealt(source, self, dealt, damage_type, is_ability)
	if health <= 0.0:
		die(source)
	return dealt


func heal(amount: float) -> void:
	if not multiplayer.is_server() or dead or amount <= 0.0:
		return
	health = minf(max_health, health + amount)
	if Game.current:
		Game.current.on_healed(self, amount)


func apply_status(kind: int, value: float, duration: float, source: Entity = null, tag: StringName = &"") -> void:
	if not multiplayer.is_server() or dead:
		return
	statuses.add(kind, value, duration, source.net_id if source else 0, tag)
	shield = statuses.shield
	status_flags = statuses.flags() | _extra_status_flags()
	if kind == GameConst.Status.STUN:
		cancel_attack_windup()
		_on_stunned()


func apply_effects(effects: Array[StatusEffectData], rank: int, source: Entity) -> void:
	for effect: StatusEffectData in effects:
		apply_status(effect.kind, effect.get_value(rank), effect.duration, source)


func die(killer: Entity) -> void:
	if dead or not multiplayer.is_server():
		return
	health = 0.0
	statuses.clear()
	shield = 0.0
	velocity = Vector3.ZERO
	cancel_attack_windup()
	dead = true
	_on_death(killer)
	died.emit(killer)
	if Game.current:
		Game.current.on_entity_killed(self, killer)


# --- Basic attacks (server) ------------------------------------------------------------

func in_attack_range(target: Entity, tolerance: float = 0.0) -> bool:
	return edge_distance_to(target) <= attack_range + tolerance


func is_winding_up() -> bool:
	return _windup_end >= 0.0


func can_start_attack(now: float) -> bool:
	return now >= _attack_ready_at and _windup_end < 0.0 and not statuses.stunned


func begin_attack(target: Entity, now: float) -> void:
	var period: float = 1.0 / get_attack_speed()
	_attack_ready_at = now + period
	_windup_end = now + clampf(period * attack_windup_ratio, 0.06, 0.45)
	_windup_target_id = target.net_id
	attack_seq += 1
	face_point(target.global_position)
	if is_inside_tree() and multiplayer.is_server():
		_play_attack_animation()


func cancel_attack_windup() -> void:
	if _windup_end >= 0.0:
		_windup_end = -1.0
		# Refund most of the attack timer so the cancelled attack can be retried quickly.
		_attack_ready_at = minf(_attack_ready_at, Game.current.game_time + 0.1 if Game.current else 0.0)


## Advances the attack windup; fires the attack when it completes. Call every server tick.
func process_attack_windup(now: float) -> void:
	if _windup_end < 0.0 or now < _windup_end:
		return
	_windup_end = -1.0
	var target: Entity = Game.current.get_entity(_windup_target_id) if Game.current else null
	if target == null or not target.is_targetable_by(team) or not in_attack_range(target, 1.5):
		return
	if attack_projectile_style == &"":
		deliver_attack(target)
	else:
		var origin: Vector3 = global_position + Vector3(0.0, bar_height * 0.45, 0.0)
		var projectile: Projectile = Game.current.spawn_projectile({
			"style": String(attack_projectile_style),
			"pos": origin,
			"dir": (target.global_position - global_position).normalized(),
			"speed": attack_projectile_speed,
			"range": 200.0,
			"radius": 0.2,
			"team": team,
			"homing": target.net_id,
		})
		if projectile:
			if Game.current:
				Game.current.play_fx("sparkle", origin, {"color": GameConst.team_color(team)})
			# The lambda must not use `self`: the attacker may be freed while the projectile flies.
			var attacker: Entity = self
			var damage_snapshot: float = attack_damage
			projectile.on_hit = func(_p: Projectile, hit: Entity) -> bool:
				if is_instance_valid(attacker) and not attacker.dead:
					attacker.deliver_attack(hit)
				elif is_instance_valid(hit):
					hit.take_damage(damage_snapshot, GameConst.DamageType.PHYSICAL, null)
				if Game.current and is_instance_valid(hit):
					var hit_pos: Vector3 = hit.global_position + Vector3(0.0, hit.bar_height * 0.45, 0.0)
					Game.current.play_fx("hit", hit_pos, {"color": GameConst.team_color(attacker.team if is_instance_valid(attacker) else team)})
				return true


## Applies basic attack damage to the target. Champions override to add on-hit effects.
func deliver_attack(target: Entity) -> void:
	target.take_damage(attack_damage, GameConst.DamageType.PHYSICAL, self, false)


func face_point(point: Vector3) -> void:
	if visual == null:
		return
	var dir := Vector2(point.x - global_position.x, point.z - global_position.z)
	if dir.length_squared() > 0.0001:
		visual.rotation.y = atan2(-dir.x, -dir.y)


func turn_towards_direction(dir: Vector3, delta: float, speed: float = 14.0) -> void:
	if visual == null or Vector2(dir.x, dir.z).length_squared() < 0.0001:
		return
	var target_yaw: float = atan2(-dir.x, -dir.z)
	visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, 1.0 - exp(-delta * speed))


# --- Client presentation -----------------------------------------------------------------

func flash_hit() -> void:
	_flash_left = 0.09


func _update_presentation(delta: float) -> void:
	if visual == null:
		return
	if _flash_left > 0.0:
		_flash_left -= delta
		_set_overlay(_get_flash_material() if _flash_left > 0.0 else null)
	if _lunge > 0.0:
		_lunge = maxf(0.0, _lunge - delta * 5.0)
		var s: float = sin(_lunge * PI)
		visual.position = Vector3(0.0, 0.0, -0.25 * s).rotated(Vector3.UP, visual.rotation.y)
	if dead and _death_anim < 1.0:
		_death_anim = minf(1.0, _death_anim + delta * 1.6)
		visual.position.y = -_death_anim * 1.2
		visual.scale = Vector3.ONE * maxf(0.05, 1.0 - _death_anim * 0.6)
		if _death_anim >= 1.0:
			visual.visible = false


func _play_attack_animation() -> void:
	_lunge = 1.0


func _on_dead_changed() -> void:
	if visual == null:
		return
	if dead:
		_death_anim = 0.0 if is_inside_tree() and Game.current and Game.current.is_playing() else 1.0
		if _death_anim >= 1.0:
			visual.visible = false
	else:
		_death_anim = 0.0
		visual.visible = true
		visual.position = Vector3.ZERO
		visual.scale = Vector3.ONE


func _set_overlay(material: Material) -> void:
	for child: Node in visual.find_children("*", "GeometryInstance3D", true, false):
		(child as GeometryInstance3D).material_overlay = material


static func _get_flash_material() -> StandardMaterial3D:
	if _flash_material == null:
		_flash_material = StandardMaterial3D.new()
		_flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_flash_material.albedo_color = Color(1.0, 1.0, 1.0, 0.55)
		_flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_flash_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	return _flash_material
