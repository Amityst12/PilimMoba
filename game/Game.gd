class_name Game
extends Node3D
## Match controller.
##
## Server: waits for every client to load, spawns structures and champions, runs the match
## rules (minion waves, respawns, fountain, rewards, win condition) and executes validated
## client commands. Clients: receive spawns / state and events, and send commands.

signal local_champion_changed(champion: Champion)
signal phase_changed(phase: int)
signal announcement(text: String, color: Color, big: bool)
signal kill_feed(entry: Dictionary)
signal command_failed(slot: int, reason: String)
signal ping_received(sender_name: String, sender_team: int, ping_type: int, world_pos: Vector3)

enum Phase { LOADING, PLAYING, ENDED }

const CHAMPION_SCENE: PackedScene = preload("res://entities/champion/Champion.tscn")
const MINION_SCENE: PackedScene = preload("res://entities/minion/Minion.tscn")
const TOWER_SCENE: PackedScene = preload("res://entities/structures/Tower.tscn")
const NEXUS_SCENE: PackedScene = preload("res://entities/structures/Nexus.tscn")
const JUNGLE_SCENE: PackedScene = preload("res://entities/jungle/JungleMonster.tscn")
const LOAD_TIMEOUT: float = 15.0
const COMMAND_BURST: float = 30.0
const COMMANDS_PER_SECOND: float = 25.0

static var current: Game

var phase: Phase = Phase.LOADING
var game_time: float = 0.0
var winner_team: int = GameConst.TEAM_NONE
var entities: Dictionary = {}
var champions: Array[Champion] = []
var minions: Array[Minion] = []
var structures: Array[Entity] = []
var local_champion: Champion

var _next_net_id: int = 1
var _loaded_peers: Dictionary = {}
var _load_elapsed: float = 0.0
var _next_wave_time: float = GameConst.FIRST_WAVE_TIME
var _wave_number: int = 0
var _spawn_queue: Array[Dictionary] = []
var _clock_timer: float = 0.0
var _fountain_timer: float = 0.0
var _first_blood_taken: bool = false
var _end_elapsed: float = 0.0
var _command_budget: Dictionary = {}

@onready var arena: Arena = $Arena
@onready var champion_spawner: MultiplayerSpawner = $ChampionSpawner
@onready var minion_spawner: MultiplayerSpawner = $MinionSpawner
@onready var structure_spawner: MultiplayerSpawner = $StructureSpawner
@onready var projectile_spawner: MultiplayerSpawner = $ProjectileSpawner
@onready var effect_spawner: MultiplayerSpawner = $EffectSpawner
@onready var monster_spawner: MultiplayerSpawner = $MonsterSpawner
@onready var local_fx: Node3D = $LocalFx
@onready var camera_rig: CameraRig = $CameraRig


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	if current == self:
		current = null


func _ready() -> void:
	champion_spawner.spawn_function = _spawn_champion
	minion_spawner.spawn_function = _spawn_minion
	structure_spawner.spawn_function = _spawn_structure
	projectile_spawner.spawn_function = _spawn_projectile
	effect_spawner.spawn_function = _spawn_effect
	monster_spawner.spawn_function = _spawn_monster
	NetworkManager.peer_left.connect(_on_peer_left)
	if multiplayer.is_server():
		_loaded_peers[multiplayer.get_unique_id()] = true
	else:
		_notify_loaded.call_deferred()


func _notify_loaded() -> void:
	_rpc_client_loaded.rpc_id(1)


func is_playing() -> bool:
	return phase == Phase.PLAYING


func local_fx_root() -> Node3D:
	return local_fx


func local_team() -> int:
	if local_champion:
		return local_champion.team
	return NetworkManager.local_team()


func all_entities() -> Array:
	return entities.values()


func get_entity(id: int) -> Entity:
	var entity: Entity = entities.get(id)
	if entity != null and is_instance_valid(entity):
		return entity
	return null


# --- Registry ---------------------------------------------------------------------------------

func register_entity(entity: Entity) -> void:
	entities[entity.net_id] = entity
	if entity is Champion:
		champions.append(entity)
	elif entity is Minion:
		minions.append(entity)
	else:
		structures.append(entity)


func unregister_entity(entity: Entity) -> void:
	if entities.get(entity.net_id) == entity:
		entities.erase(entity.net_id)
	if entity is Champion:
		champions.erase(entity)
		if entity == local_champion:
			local_champion = null
	elif entity is Minion:
		minions.erase(entity)
	else:
		structures.erase(entity)


# --- Spawn functions (run on every peer) --------------------------------------------------------

func _spawn_champion(data: Dictionary) -> Node:
	var champion := CHAMPION_SCENE.instantiate() as Champion
	champion.name = "C%d" % int(data["id"])
	champion.net_id = int(data["id"])
	champion.team = int(data["team"])
	champion.champion_id = String(data["champion"])
	champion.player_name = String(data["name"])
	champion.owner_peer_id = int(data["owner"])
	champion.is_bot = bool(data["bot"])
	champion.position = data["pos"]
	champion.net_position = data["pos"]
	return champion


func _spawn_minion(data: Dictionary) -> Node:
	var minion := MINION_SCENE.instantiate() as Minion
	minion.name = "M%d" % int(data["id"])
	minion.net_id = int(data["id"])
	minion.team = int(data["team"])
	minion.minion_type = int(data["type"])
	minion.wave = int(data["wave"])
	minion.position = data["pos"]
	minion.net_position = data["pos"]
	return minion


func _spawn_structure(data: Dictionary) -> Node:
	var structure: Entity
	if String(data["kind"]) == "tower":
		var tower := TOWER_SCENE.instantiate() as Tower
		tower.tier = int(data["tier"])
		structure = tower
	else:
		structure = NEXUS_SCENE.instantiate() as Nexus
	structure.name = "S%d" % int(data["id"])
	structure.net_id = int(data["id"])
	structure.team = int(data["team"])
	structure.position = data["pos"]
	structure.net_position = data["pos"]
	return structure


func _spawn_projectile(data: Dictionary) -> Node:
	var projectile := Projectile.new()
	projectile.setup(data)
	projectile.name = "P%d" % projectile.net_id
	return projectile


func _spawn_effect(data: Dictionary) -> Node:
	var node: Node3D
	if String(data.get("effect", "area")) == "beam":
		var beam := BeamEffect.new()
		beam.setup(data)
		node = beam
	else:
		var area := AreaEffect.new()
		area.setup(data)
		node = area
	node.name = "E%d" % int(data["id"])
	return node


func _spawn_monster(data: Dictionary) -> Node:
	var monster := JUNGLE_SCENE.instantiate() as JungleMonster
	monster.name = "J%d" % int(data["id"])
	monster.net_id = int(data["id"])
	monster.monster_type = int(data["type"]) as JungleMonster.MonsterType
	monster.position = data["pos"]
	monster.net_position = data["pos"]
	return monster


# --- Server spawning API ---------------------------------------------------------------------------

func _alloc_id() -> int:
	_next_net_id += 1
	return _next_net_id


func spawn_projectile(params: Dictionary) -> Projectile:
	if not multiplayer.is_server() or phase != Phase.PLAYING:
		return null
	var data: Dictionary = params.duplicate()
	data["id"] = _alloc_id()
	return projectile_spawner.spawn(data) as Projectile


func spawn_area_effect(params: Dictionary) -> AreaEffect:
	if not multiplayer.is_server() or phase != Phase.PLAYING:
		return null
	var data: Dictionary = params.duplicate()
	data["id"] = _alloc_id()
	data["effect"] = "area"
	return effect_spawner.spawn(data) as AreaEffect


func spawn_beam(params: Dictionary) -> BeamEffect:
	if not multiplayer.is_server() or phase != Phase.PLAYING:
		return null
	var data: Dictionary = params.duplicate()
	data["id"] = _alloc_id()
	data["effect"] = "beam"
	return effect_spawner.spawn(data) as BeamEffect


func spawn_minion(minion_type: int, team: int) -> Minion:
	var jitter := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-2.0, 2.0))
	var minion := minion_spawner.spawn({
		"id": _alloc_id(), "type": minion_type, "team": team, "wave": _wave_number,
		"pos": Arena.minion_spawn_position(team) + jitter,
	}) as Minion
	if minion:
		minion.lane_waypoints = Arena.lane_waypoints(team)
	return minion


# --- Match flow (server) ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		if phase == Phase.PLAYING:
			game_time += delta
		return
	match phase:
		Phase.LOADING:
			_load_elapsed += delta
			if arena.nav_ready and (_all_peers_loaded() or _load_elapsed > LOAD_TIMEOUT):
				_begin_match()
		Phase.PLAYING:
			game_time += delta
			_run_rules(delta)
		Phase.ENDED:
			_end_elapsed += delta
			if _end_elapsed > GameConst.END_SCREEN_AUTO_RETURN and NetworkManager.is_online_host():
				_end_elapsed = -INF
				NetworkManager.return_to_lobby()


func _all_peers_loaded() -> bool:
	for id: int in NetworkManager.players:
		var info: Dictionary = NetworkManager.players[id]
		if not bool(info["bot"]) and not _loaded_peers.has(id):
			return false
	return true


func _begin_match() -> void:
	for id: int in NetworkManager.players.keys():
		var info: Dictionary = NetworkManager.players[id]
		if not bool(info["bot"]) and not _loaded_peers.has(id):
			push_warning("Peer %d did not load in time, converting to bot." % id)
			info["bot"] = true
	for structure: Dictionary in Arena.structure_layout():
		structure_spawner.spawn({
			"id": _alloc_id(), "kind": structure["kind"], "team": structure["team"],
			"tier": structure["tier"], "pos": structure["pos"],
		})
	var team_slots: Dictionary = {GameConst.TEAM_BLUE: 0, GameConst.TEAM_RED: 0}
	for id: int in NetworkManager.players:
		var info: Dictionary = NetworkManager.players[id]
		var team: int = int(info["team"])
		var slot: int = team_slots.get(team, 0)
		team_slots[team] = slot + 1
		var angle: float = TAU * float(slot) / 5.0
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * (2.2 if slot > 0 else 0.0)
		champion_spawner.spawn({
			"id": _alloc_id(), "team": team, "champion": String(info["champion"]), "name": String(info["name"]),
			"owner": 0 if bool(info["bot"]) else id, "bot": bool(info["bot"]),
			"pos": Arena.fountain_position(team) + offset,
		})

	# Spawn Jungle Camps & Rift Behemoth
	var jungle_camps: Array[Dictionary] = [
		{"type": JungleMonster.MonsterType.BLUE_GOLEM, "pos": Vector3(-24.0, 0.0, 22.0)},
		{"type": JungleMonster.MonsterType.BLUE_GOLEM, "pos": Vector3(24.0, 0.0, -22.0)},
		{"type": JungleMonster.MonsterType.RED_BRAMBLE, "pos": Vector3(-24.0, 0.0, -22.0)},
		{"type": JungleMonster.MonsterType.RED_BRAMBLE, "pos": Vector3(24.0, 0.0, 22.0)},
		{"type": JungleMonster.MonsterType.RIFT_BEHEMOTH, "pos": Vector3(0.0, 0.0, 22.0)},
	]
	for camp: Dictionary in jungle_camps:
		monster_spawner.spawn({
			"id": _alloc_id(), "type": camp["type"], "pos": camp["pos"]
		})

	phase = Phase.PLAYING
	game_time = 0.0
	_rpc_phase.rpc(Phase.PLAYING, 0.0)
	announce("Welcome to Pilim Arena!", Color(1.0, 0.9, 0.6), true)


func _run_rules(delta: float) -> void:
	if game_time >= _next_wave_time:
		_wave_number += 1
		_next_wave_time += GameConst.WAVE_INTERVAL
		_queue_wave()
		if _wave_number == 1:
			announce("Minions have spawned!", Color(0.85, 0.9, 1.0), false)
	_process_spawn_queue()
	for champion: Champion in champions:
		if champion.dead and game_time >= champion.respawn_at:
			champion.respawn()
	for minion: Minion in minions:
		if minion.dead and game_time - minion.death_time > 1.4 and not minion.is_queued_for_deletion():
			minion.queue_free()
	_fountain_timer -= delta
	if _fountain_timer <= 0.0:
		_fountain_timer = 0.25
		_process_fountains(0.25)
	_clock_timer -= delta
	if _clock_timer <= 0.0:
		_clock_timer = 0.5
		_rpc_clock.rpc(game_time)


func _queue_wave() -> void:
	for team: int in [GameConst.TEAM_BLUE, GameConst.TEAM_RED]:
		var t: float = game_time
		for i: int in range(GameConst.WAVE_MELEE_COUNT):
			_spawn_queue.append({"time": t, "type": Minion.MinionType.MELEE, "team": team})
			t += GameConst.WAVE_SPAWN_SPACING
		for i: int in range(GameConst.WAVE_CASTER_COUNT):
			_spawn_queue.append({"time": t, "type": Minion.MinionType.CASTER, "team": team})
			t += GameConst.WAVE_SPAWN_SPACING


func _process_spawn_queue() -> void:
	while not _spawn_queue.is_empty() and float(_spawn_queue[0]["time"]) <= game_time:
		var entry: Dictionary = _spawn_queue.pop_front()
		spawn_minion(int(entry["type"]), int(entry["team"]))


func _process_fountains(step: float) -> void:
	for champion: Champion in champions:
		if champion.dead:
			continue
		if is_in_fountain(champion):
			champion.heal(champion.max_health * GameConst.FOUNTAIN_HEAL_FRACTION * step)
			champion.mana = minf(champion.max_mana, champion.mana + champion.max_mana * GameConst.FOUNTAIN_HEAL_FRACTION * step)
		var enemy_fountain: Vector3 = Arena.fountain_position(GameConst.enemy_team(champion.team))
		if champion.planar_distance_to_point(enemy_fountain) <= GameConst.FOUNTAIN_RADIUS + 1.0:
			champion.take_damage(GameConst.FOUNTAIN_ENEMY_DPS * step, GameConst.DamageType.TRUE, null)
			play_fx("hit", champion.global_position + Vector3(0.0, 1.2, 0.0), {"color": GameConst.team_color(GameConst.enemy_team(champion.team))})


func is_in_fountain(champion: Champion) -> bool:
	return champion.planar_distance_to_point(Arena.fountain_position(champion.team)) <= GameConst.FOUNTAIN_RADIUS


func fountain_position(team: int) -> Vector3:
	return Arena.fountain_position(team)


func is_structure_vulnerable(structure: Entity) -> bool:
	if structure is Tower:
		var tier: int = (structure as Tower).tier
		return tier <= 1 or _tower_destroyed(structure.team, tier - 1)
	if structure is Nexus:
		return _tower_destroyed(structure.team, 2)
	return true


func _tower_destroyed(team: int, tier: int) -> bool:
	for structure: Entity in structures:
		if structure is Tower and structure.team == team and (structure as Tower).tier == tier:
			return structure.dead
	return true


# --- Combat events (server) ---------------------------------------------------------------------------

func on_damage_dealt(source: Entity, target: Entity, amount: float, damage_type: int, is_ability: bool) -> void:
	if amount >= 1.0:
		var pos: Vector3 = target.global_position + Vector3(0.0, target.bar_height + 0.2, 0.0)
		var text: String = str(roundi(amount))
		var source_owner: int = (source as Champion).owner_peer_id if source is Champion else 0
		if source_owner != 0:
			_send_float_text(source_owner, pos, text, GameConst.damage_type_color(damage_type), 46 if is_ability else 38)
		if target is Champion and (target as Champion).owner_peer_id != 0 and (target as Champion).owner_peer_id != source_owner:
			_send_float_text((target as Champion).owner_peer_id, pos, "-" + text, Color(1.0, 0.32, 0.3), 40)
	if source is Champion and target is Champion:
		for structure: Entity in structures:
			if structure is Tower and structure.team == target.team:
				(structure as Tower).notify_champion_attacked(source, target, game_time)
		for minion: Minion in minions:
			if minion.team == target.team and not minion.dead and minion.planar_distance_to_point(target.global_position) < 9.0:
				minion.call_for_help(source, game_time)


func on_ability_cast(champion: Champion, slot: int) -> void:
	var ability: AbilityData = champion.get_ability(slot)
	if ability:
		_rpc_sound.rpc(String(ability.cast_sound), champion.global_position)


func on_entity_killed(victim: Entity, killer: Entity) -> void:
	play_fx("death", victim.global_position, {"color": GameConst.team_color(victim.team)})
	if victim is Minion:
		_on_minion_killed(victim as Minion, killer)
	elif victim is Champion:
		_on_champion_killed(victim as Champion, killer)
	elif victim is Tower:
		_on_tower_destroyed(victim as Tower, killer)
	elif victim is Nexus:
		_on_nexus_destroyed(victim as Nexus)


func _on_minion_killed(minion: Minion, killer: Entity) -> void:
	var killer_champion := killer as Champion
	if killer_champion:
		killer_champion.add_gold(minion.gold_value)
		killer_champion.creep_score += 1
		if killer_champion.owner_peer_id != 0:
			_send_float_text(killer_champion.owner_peer_id, minion.global_position + Vector3(0.0, 2.2, 0.0),
					"+%dg" % minion.gold_value, GameConst.COLOR_GOLD, 36)
			_send_sound(killer_champion.owner_peer_id, "gold", minion.global_position)
	_grant_shared_xp(minion.team, minion.global_position, minion.xp_value)


func _grant_shared_xp(victim_team: int, pos: Vector3, amount: float) -> void:
	var receivers: Array[Champion] = []
	for champion: Champion in champions:
		if champion.team != victim_team and not champion.dead \
				and champion.planar_distance_to_point(pos) <= GameConst.XP_SHARE_RADIUS:
			receivers.append(champion)
	if receivers.is_empty():
		return
	var share: float = amount if receivers.size() == 1 else amount * 1.3 / float(receivers.size())
	for champion: Champion in receivers:
		champion.add_xp(share)


func _on_champion_killed(victim: Champion, killer: Entity) -> void:
	var killer_champion := killer as Champion
	if killer_champion == null or killer_champion.team == victim.team:
		killer_champion = _most_recent_damager(victim)
	var assisters: Array[Champion] = []
	for id: int in victim.damage_log:
		if game_time - float(victim.damage_log[id]) > GameConst.ASSIST_WINDOW:
			continue
		var champion := get_entity(id) as Champion
		if champion and champion != killer_champion and champion.team != victim.team:
			assisters.append(champion)
	victim.damage_log.clear()

	var kill_xp: float = GameConst.CHAMPION_KILL_XP_BASE + GameConst.CHAMPION_KILL_XP_PER_LEVEL * float(victim.level)
	if killer_champion:
		killer_champion.kills += 1
		var gold: int = GameConst.KILL_GOLD
		if not _first_blood_taken:
			_first_blood_taken = true
			gold += GameConst.FIRST_BLOOD_BONUS
			announce("First Blood!", Color(1.0, 0.35, 0.3), true)
		killer_champion.add_gold(gold)
		killer_champion.add_xp(kill_xp)
		if killer_champion.owner_peer_id != 0:
			_send_float_text(killer_champion.owner_peer_id, victim.global_position + Vector3(0.0, 3.0, 0.0),
					"+%dg" % gold, GameConst.COLOR_GOLD, 48)
		_announce_streak(killer_champion)
	if not assisters.is_empty():
		var assist_gold: int = int(float(GameConst.ASSIST_GOLD_POOL) / float(assisters.size()))
		for champion: Champion in assisters:
			champion.assists += 1
			champion.add_gold(assist_gold)
			champion.add_xp(kill_xp * 0.4)
	var killer_name: String = killer_champion.player_name if killer_champion else (killer.get_display_name() if killer else "Fountain")
	var entry: Dictionary = {
		"killer": killer_name,
		"killer_team": killer_champion.team if killer_champion else (killer.team if killer else GameConst.enemy_team(victim.team)),
		"killer_champion": killer_champion.champion_id if killer_champion else "",
		"victim": victim.player_name,
		"victim_team": victim.team,
		"victim_champion": victim.champion_id,
		"assists": assisters.size(),
	}
	_rpc_kill_feed.rpc(entry)


func _most_recent_damager(victim: Champion) -> Champion:
	var best: Champion = null
	var best_time: float = -INF
	for id: int in victim.damage_log:
		var t: float = float(victim.damage_log[id])
		if game_time - t <= GameConst.ASSIST_WINDOW and t > best_time:
			var champion := get_entity(id) as Champion
			if champion and champion.team != victim.team:
				best = champion
				best_time = t
	return best


func _announce_streak(champion: Champion) -> void:
	champion.kill_streak += 1
	if game_time - champion.last_kill_time <= 10.0:
		champion.multi_kill_count += 1
	else:
		champion.multi_kill_count = 1
	champion.last_kill_time = game_time
	var color: Color = GameConst.team_color(champion.team).lightened(0.3)
	match champion.multi_kill_count:
		2:
			announce("%s: Double Kill!" % champion.player_name, color, true)
			return
		3:
			announce("%s: Triple Kill!" % champion.player_name, color, true)
			return
		4:
			announce("%s: Quadra Kill!" % champion.player_name, color, true)
			return
		5:
			announce("%s: PENTAKILL!" % champion.player_name, color, true)
			return
	match champion.kill_streak:
		3:
			announce("%s is on a killing spree!" % champion.player_name, color, false)
		5:
			announce("%s is unstoppable!" % champion.player_name, color, false)
		7:
			announce("%s is legendary!" % champion.player_name, color, true)


func _on_tower_destroyed(tower: Tower, killer: Entity) -> void:
	for champion: Champion in champions:
		if champion.team != tower.team:
			champion.add_gold(GameConst.TOWER_TEAM_GOLD)
	play_fx("explosion", tower.global_position, {"color": GameConst.team_color(tower.team), "radius": 5.0})
	_rpc_structure_destroyed.rpc(tower.team, "tower")
	var killer_champion := killer as Champion
	_rpc_kill_feed.rpc({
		"killer": killer_champion.player_name if killer_champion else "Minions",
		"killer_team": GameConst.enemy_team(tower.team),
		"killer_champion": killer_champion.champion_id if killer_champion else "",
		"victim": tower.get_display_name(),
		"victim_team": tower.team,
		"victim_champion": "",
		"assists": 0,
	})


func _on_nexus_destroyed(nexus: Nexus) -> void:
	play_fx("explosion", nexus.global_position, {"color": GameConst.team_color(nexus.team), "radius": 9.0})
	end_match(GameConst.enemy_team(nexus.team))


func end_match(winner: int) -> void:
	if phase == Phase.ENDED or not multiplayer.is_server():
		return
	phase = Phase.ENDED
	winner_team = winner
	_end_elapsed = 0.0
	_spawn_queue.clear()
	_rpc_match_over.rpc(winner, game_time)


## Frees every networked entity so despawns replicate before the scene changes.
func cleanup_networked_entities() -> void:
	if not multiplayer.is_server():
		return
	for container: Node in [$World/Projectiles, $World/Effects, $World/Minions, $World/Champions, $World/Structures, $World/Monsters]:
		for child: Node in container.get_children():
			child.queue_free()


# --- Queries ----------------------------------------------------------------------------------------

func find_enemies_in_radius(team: int, point: Vector3, search_radius: float, include_structures: bool = false) -> Array[Entity]:
	var result: Array[Entity] = []
	for entity: Entity in entities.values():
		if entity.team == team or not entity.is_targetable_by(team):
			continue
		if entity.is_structure() and not include_structures:
			continue
		if entity.planar_distance_to_point(point) <= search_radius + entity.radius:
			result.append(entity)
	return result


func find_enemies_on_segment(team: int, from: Vector3, to: Vector3, half_width: float) -> Array[Entity]:
	var result: Array[Entity] = []
	var a := Vector2(from.x, from.z)
	var b := Vector2(to.x, to.z)
	for entity: Entity in entities.values():
		if entity.team == team or entity.is_structure() or not entity.is_targetable_by(team):
			continue
		var p := Vector2(entity.global_position.x, entity.global_position.z)
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(p, a, b)
		if closest.distance_to(p) <= half_width + entity.radius:
			result.append(entity)
	return result


func clamp_to_map(point: Vector3) -> Vector3:
	if not point.is_finite():
		return Vector3.ZERO
	return Arena.clamp_to_bounds(point)


func clamp_to_navmesh(point: Vector3) -> Vector3:
	var map: RID = get_world_3d().navigation_map
	var closest: Vector3 = NavigationServer3D.map_get_closest_point(map, clamp_to_map(point))
	closest.y = 0.0
	return closest


# --- Commands (client -> server) ----------------------------------------------------------------------

func _commanding_champion() -> Champion:
	if not multiplayer.is_server() or phase != Phase.PLAYING:
		return null
	var sender: int = multiplayer.get_remote_sender_id()
	if sender == 0:
		sender = multiplayer.get_unique_id()
	# Token bucket rate limiting against command spam.
	var now: float = Time.get_ticks_msec() / 1000.0
	var bucket: Array = _command_budget.get(sender, [COMMAND_BURST, now])
	var tokens: float = minf(COMMAND_BURST, float(bucket[0]) + (now - float(bucket[1])) * COMMANDS_PER_SECOND)
	if tokens < 1.0:
		_command_budget[sender] = [tokens, now]
		return null
	_command_budget[sender] = [tokens - 1.0, now]
	for champion: Champion in champions:
		if champion.owner_peer_id == sender and not champion.is_bot:
			return champion
	return null


@rpc("any_peer", "call_local", "reliable")
func cmd_move(point: Vector3) -> void:
	var champion: Champion = _commanding_champion()
	if champion and point.is_finite():
		champion.order_move(point)


@rpc("any_peer", "call_local", "reliable")
func cmd_attack(target_id: int) -> void:
	var champion: Champion = _commanding_champion()
	if champion:
		champion.order_attack(get_entity(target_id))


@rpc("any_peer", "call_local", "reliable")
func cmd_attack_move(point: Vector3) -> void:
	var champion: Champion = _commanding_champion()
	if champion and point.is_finite():
		champion.order_attack_move(point)


@rpc("any_peer", "call_local", "reliable")
func cmd_stop() -> void:
	var champion: Champion = _commanding_champion()
	if champion:
		champion.order_stop()


@rpc("any_peer", "call_local", "reliable")
func cmd_cast(slot: int, point: Vector3, target_id: int) -> void:
	var champion: Champion = _commanding_champion()
	if champion == null or not point.is_finite():
		return
	var error: String = champion.try_cast(slot, point, target_id)
	if error != "":
		_notify_command_failed(champion.owner_peer_id, slot, error)


@rpc("any_peer", "call_local", "reliable")
func cmd_level_ability(slot: int) -> void:
	var champion: Champion = _commanding_champion()
	if champion and champion.level_ability(slot):
		_send_sound(champion.owner_peer_id, "level_ability", champion.global_position)


@rpc("any_peer", "call_local", "reliable")
func cmd_recall() -> void:
	var champion: Champion = _commanding_champion()
	if champion:
		champion.start_recall()


@rpc("any_peer", "call_local", "reliable")
func cmd_buy(item_id: String) -> void:
	var champion: Champion = _commanding_champion()
	if champion == null:
		return
	var error: String = champion.buy_item(item_id)
	if error != "":
		_notify_command_failed(champion.owner_peer_id, -1, error)
	else:
		_send_sound(champion.owner_peer_id, "buy", champion.global_position)


@rpc("any_peer", "call_local", "reliable")
func cmd_sell(index: int) -> void:
	var champion: Champion = _commanding_champion()
	if champion == null:
		return
	var error: String = champion.sell_item(index)
	if error != "":
		_notify_command_failed(champion.owner_peer_id, -1, error)
	else:
		_send_sound(champion.owner_peer_id, "buy", champion.global_position)


@rpc("any_peer", "call_local", "reliable")
func cmd_ping(ping_type: int, point: Vector3) -> void:
	var champion: Champion = _commanding_champion()
	if champion and point.is_finite():
		_rpc_ping.rpc(champion.player_name, champion.team, ping_type, point)


@rpc("authority", "call_local", "reliable")
func _rpc_ping(sender_name: String, sender_team: int, ping_type: int, point: Vector3) -> void:
	var my_champ: Champion = local_champion
	if my_champ and my_champ.team != sender_team:
		return
	var col: Color = GameConst.ping_color(ping_type)
	if local_fx:
		Fx.ping_marker(local_fx, point, ping_type, col)
	Sfx.play("blink")
	ping_received.emit(sender_name, sender_team, ping_type, point)


func _notify_command_failed(peer_id: int, slot: int, reason: String) -> void:
	if peer_id == multiplayer.get_unique_id():
		_rpc_command_failed(slot, reason)
	elif peer_id != 0:
		_rpc_command_failed.rpc_id(peer_id, slot, reason)


# --- Events (server -> clients) -------------------------------------------------------------------------

func play_fx(kind: String, pos: Vector3, params: Dictionary = {}) -> void:
	if multiplayer.is_server():
		_rpc_fx.rpc(kind, pos, params)


func announce(text: String, color: Color, big: bool) -> void:
	if multiplayer.is_server():
		_rpc_announce.rpc(text, color, big)


func shake_camera_at(pos: Vector3, strength: float) -> void:
	if camera_rig:
		var distance: float = Vector2(camera_rig.focus.x - pos.x, camera_rig.focus.z - pos.z).length()
		camera_rig.add_trauma(strength * clampf(1.0 - distance / 28.0, 0.0, 1.0))


func _send_float_text(peer_id: int, pos: Vector3, text: String, color: Color, size: int) -> void:
	if peer_id == multiplayer.get_unique_id():
		_rpc_float_text(pos, text, color, size)
	elif peer_id > 0:
		_rpc_float_text.rpc_id(peer_id, pos, text, color, size)


func _send_sound(peer_id: int, sound: String, pos: Vector3) -> void:
	if peer_id == multiplayer.get_unique_id():
		_rpc_sound(sound, pos)
	elif peer_id > 0:
		_rpc_sound.rpc_id(peer_id, sound, pos)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_client_loaded() -> void:
	if multiplayer.is_server():
		_loaded_peers[multiplayer.get_remote_sender_id()] = true


@rpc("authority", "call_remote", "reliable")
func _rpc_phase(new_phase: int, time: float) -> void:
	phase = new_phase as Phase
	game_time = time
	phase_changed.emit(phase)


@rpc("authority", "call_remote", "unreliable")
func _rpc_clock(time: float) -> void:
	if absf(time - game_time) > 0.35:
		game_time = time
	else:
		game_time = lerpf(game_time, time, 0.2)


@rpc("authority", "call_local", "unreliable")
func _rpc_fx(kind: String, pos: Vector3, params: Dictionary) -> void:
	Fx.play(kind, local_fx, pos, params)
	match kind:
		"explosion":
			shake_camera_at(pos, 0.8)
			Sfx.play_at("explosion", pos)
		"blink":
			Sfx.play_at("blink", pos)
		"levelup":
			if local_champion and local_champion.planar_distance_to_point(pos) < 1.0:
				Sfx.play("levelup")
		"death":
			Sfx.play_at("death", pos, -6.0)
		"hit", "impact":
			Sfx.play_at("hit", pos, -4.0)


@rpc("authority", "call_local", "unreliable")
func _rpc_sound(sound: String, pos: Vector3) -> void:
	Sfx.play_at(sound, pos)


@rpc("authority", "call_remote", "unreliable")
func _rpc_float_text(pos: Vector3, text: String, color: Color, size: int) -> void:
	Fx.floating_text(local_fx, pos, text, color, size)


@rpc("authority", "call_local", "reliable")
func _rpc_announce(text: String, color: Color, big: bool) -> void:
	announcement.emit(text, color, big)
	if big:
		Sfx.play("announce")


@rpc("authority", "call_local", "reliable")
func _rpc_kill_feed(entry: Dictionary) -> void:
	kill_feed.emit(entry)


@rpc("authority", "call_local", "reliable")
func _rpc_structure_destroyed(team: int, _kind: String) -> void:
	if team == local_team():
		announcement.emit("Your turret has been destroyed!", GameConst.COLOR_RED, false)
	else:
		announcement.emit("Enemy turret destroyed!", GameConst.COLOR_BLUE.lightened(0.3), false)


@rpc("authority", "call_local", "reliable")
func _rpc_match_over(winner: int, time: float) -> void:
	phase = Phase.ENDED
	winner_team = winner
	game_time = time
	phase_changed.emit(phase)
	Sfx.play("victory" if winner == local_team() else "defeat")


@rpc("authority", "call_remote", "reliable")
func _rpc_command_failed(slot: int, reason: String) -> void:
	command_failed.emit(slot, reason)


# --- Local player binding ------------------------------------------------------------------------------------

func _process(_delta: float) -> void:
	if local_champion == null:
		for champion: Champion in champions:
			if champion.is_local():
				local_champion = champion
				local_champion_changed.emit(champion)
				if camera_rig:
					camera_rig.follow_target = champion
					camera_rig.snap_to(champion.global_position)
				break


func _on_peer_left(peer_id: int, player_name: String) -> void:
	if not multiplayer.is_server():
		return
	_loaded_peers.erase(peer_id)
	for champion: Champion in champions:
		if champion.owner_peer_id == peer_id:
			champion.convert_to_bot()
			announce("%s disconnected - a bot took over." % player_name, Color(0.8, 0.8, 0.8), false)
