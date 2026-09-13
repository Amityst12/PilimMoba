class_name Minion
extends Entity
## Lane minion. Marches along its lane, fights enemy minions first, answers calls for help
## when an enemy champion attacks an allied champion, and sieges structures.

enum MinionType { MELEE, CASTER }

const ACQUIRE_RANGE: float = 7.0
const LEASH_RANGE: float = 11.0
const HELP_DURATION: float = 3.0

# Replicated (spawn)
var minion_type: int = MinionType.MELEE
var wave: int = 0

# Server
var gold_value: int = 20
var xp_value: float = 50.0
var lane_waypoints: PackedVector3Array = PackedVector3Array()
var death_time: float = -1.0

var _waypoint_index: int = 0
var _target_id: int = -1
var _help_target_id: int = -1
var _help_until: float = 0.0
var _reevaluate_timer: float = 0.0
var _repath_timer: float = 0.0
var _desired_velocity: Vector3 = Vector3.ZERO

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D


func _ready() -> void:
	_configure_stats()
	nav_agent.radius = radius + 0.1
	nav_agent.max_speed = base_move_speed + 1.0
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	if not multiplayer.is_server():
		nav_agent.avoidance_enabled = false
	super._ready()
	_build_model()


func get_kind() -> Kind:
	return Kind.MINION


func get_display_name() -> String:
	return "Caster Minion" if minion_type == MinionType.CASTER else "Melee Minion"


func _configure_stats() -> void:
	var scale_steps: float = float(wave)
	if minion_type == MinionType.CASTER:
		max_health = 290.0 + 11.0 * scale_steps
		attack_damage = 24.0 + 1.2 * scale_steps
		base_attack_speed = 0.75
		attack_range = 6.0
		armor = 0.0
		magic_resist = 0.0
		radius = 0.42
		attack_projectile_style = &"caster_minion"
		attack_projectile_speed = 16.0
		attack_windup_ratio = 0.35
		gold_value = 16
		xp_value = 32.0
		bar_height = 1.7
	else:
		max_health = 450.0 + 20.0 * scale_steps
		attack_damage = 13.0 + 0.8 * scale_steps
		base_attack_speed = 1.1
		attack_range = 1.0
		armor = 12.0
		magic_resist = 0.0
		radius = 0.48
		attack_projectile_style = &""
		attack_windup_ratio = 0.3
		gold_value = 22
		xp_value = 60.0
		bar_height = 1.8
	base_move_speed = 4.7
	health = max_health


func _build_model() -> void:
	if visual == null:
		return
	var model := MinionModel.build(minion_type, team)
	visual.add_child(model)


## Called by an allied champion's attacker detection: enemy champion hit our champion nearby.
func call_for_help(attacker: Entity, now: float) -> void:
	if dead or attacker == null or attacker.team == team:
		return
	var current: Entity = Game.current.get_entity(_target_id)
	# Minions already fighting a champion keep their target.
	if current and current is Champion and current.is_targetable_by(team):
		return
	_help_target_id = attacker.net_id
	_help_until = now + HELP_DURATION
	_reevaluate_timer = 0.0


func _server_tick(delta: float, now: float) -> void:
	process_attack_windup(now)
	_reevaluate_timer -= delta
	var target: Entity = Game.current.get_entity(_target_id)
	if _reevaluate_timer <= 0.0 or target == null or not target.is_targetable_by(team):
		_reevaluate_timer = 0.25
		target = _pick_target(now)
		_target_id = target.net_id if target else -1

	_desired_velocity = Vector3.ZERO
	if statuses.stunned:
		_apply_desired_velocity()
		return
	if target:
		if in_attack_range(target):
			face_point(target.global_position)
			if can_start_attack(now):
				begin_attack(target, now)
		elif not is_winding_up():
			_repath_timer -= delta
			if _repath_timer <= 0.0:
				_repath_timer = 0.3
				nav_agent.target_position = target.flat_position()
			_steer_along_path()
	else:
		_follow_lane()
	_apply_desired_velocity()


func _pick_target(now: float) -> Entity:
	var game := Game.current
	if _help_target_id >= 0 and now < _help_until:
		var helper_target: Entity = game.get_entity(_help_target_id)
		if helper_target and helper_target.is_targetable_by(team) and edge_distance_to(helper_target) < LEASH_RANGE:
			return helper_target
	_help_target_id = -1
	var current: Entity = game.get_entity(_target_id)
	if current and current.is_targetable_by(team) and edge_distance_to(current) < ACQUIRE_RANGE + 1.5:
		# Keep attacking, but always switch from structures / champions to minions when they arrive.
		if current is Minion:
			return current
		var closest_minion: Entity = _closest_enemy(ACQUIRE_RANGE, Kind.MINION)
		return closest_minion if closest_minion else current
	var minion: Entity = _closest_enemy(ACQUIRE_RANGE, Kind.MINION)
	if minion:
		return minion
	var champion: Entity = _closest_enemy(ACQUIRE_RANGE, Kind.CHAMPION)
	if champion:
		return champion
	return _closest_structure(ACQUIRE_RANGE + 2.0)


func _closest_enemy(search_range: float, kind: Kind) -> Entity:
	var best: Entity = null
	var best_distance: float = INF
	var list: Array = Game.current.minions if kind == Kind.MINION else Game.current.champions
	for entity: Entity in list:
		if not entity.is_targetable_by(team):
			continue
		var d: float = edge_distance_to(entity)
		if d < search_range and d < best_distance:
			best_distance = d
			best = entity
	return best


func _closest_structure(search_range: float) -> Entity:
	var best: Entity = null
	var best_distance: float = INF
	for entity: Entity in Game.current.structures:
		if not entity.is_targetable_by(team):
			continue
		var d: float = edge_distance_to(entity)
		if d < search_range and d < best_distance:
			best_distance = d
			best = entity
	return best


func _follow_lane() -> void:
	if lane_waypoints.is_empty():
		return
	_waypoint_index = clampi(_waypoint_index, 0, lane_waypoints.size() - 1)
	var waypoint: Vector3 = lane_waypoints[_waypoint_index]
	if planar_distance_to_point(waypoint) < 2.5 and _waypoint_index < lane_waypoints.size() - 1:
		_waypoint_index += 1
		waypoint = lane_waypoints[_waypoint_index]
	if nav_agent.target_position.distance_squared_to(waypoint) > 0.25:
		nav_agent.target_position = waypoint
	_steer_along_path()


func _steer_along_path() -> void:
	if statuses.rooted or nav_agent.is_navigation_finished():
		return
	var next: Vector3 = nav_agent.get_next_path_position()
	var offset := Vector3(next.x - global_position.x, 0.0, next.z - global_position.z)
	if offset.length_squared() > 0.0001:
		_desired_velocity = offset.normalized() * get_move_speed()


func _apply_desired_velocity() -> void:
	if nav_agent.avoidance_enabled:
		nav_agent.velocity = _desired_velocity
	else:
		_on_velocity_computed(_desired_velocity)


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	if not multiplayer.is_server() or dead or Game.current == null or not Game.current.is_playing():
		return
	velocity = Vector3(safe_velocity.x, 0.0, safe_velocity.z)
	if velocity.length_squared() > 0.01:
		move_and_slide()
		global_position.y = 0.0
		if not is_winding_up():
			turn_towards_direction(velocity, get_physics_process_delta_time(), 10.0)
	net_position = global_position
	net_velocity = velocity


func _on_death(_killer: Entity) -> void:
	collision_layer = 0
	nav_agent.avoidance_enabled = false
	death_time = Game.current.game_time if Game.current else 0.0
