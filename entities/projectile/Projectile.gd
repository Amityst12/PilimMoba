class_name Projectile
extends Node3D
## Networked projectile (skillshots, basic attacks, tower shots).
##
## Spawned by the server through Game.projectile_spawner with a data dictionary.
## Both server and clients simulate the same deterministic motion from the spawn data,
## so no per-frame position sync is needed. Only the server detects hits.
## Clients never free the node themselves; they hide it and wait for the server despawn.

# Spawn data (identical on every peer)
var net_id: int = 0
var style: String = ""
var direction: Vector3 = Vector3.FORWARD
var speed: float = 20.0
var max_range: float = 10.0
var hit_radius: float = 0.3
var team: int = GameConst.TEAM_NONE
var homing_id: int = -1
var tint: Color = Color.WHITE

# Server-only
## func(projectile: Projectile, target: Entity) -> bool. Return true to destroy the projectile.
var on_hit: Callable
var hit_ids: Dictionary = {}
var hits_structures: bool = false

var _traveled: float = 0.0
var _finished: bool = false
var _last_target_point: Vector3


func setup(data: Dictionary) -> void:
	net_id = int(data.get("id", 0))
	style = String(data.get("style", ""))
	position = data.get("pos", Vector3.ZERO)
	direction = (data.get("dir", Vector3.FORWARD) as Vector3).normalized()
	speed = float(data.get("speed", 20.0))
	max_range = float(data.get("range", 10.0))
	hit_radius = float(data.get("radius", 0.3))
	team = int(data.get("team", 0))
	homing_id = int(data.get("homing", -1))
	tint = data.get("color", GameConst.team_color(team))
	_last_target_point = position + direction * max_range


func _ready() -> void:
	FxStyles.build_projectile_visual(self, style, tint, team)
	if direction.length_squared() > 0.001:
		look_at(global_position + direction, Vector3.UP)


func _physics_process(delta: float) -> void:
	if _finished:
		return
	var is_server: bool = multiplayer.is_server()
	var game := Game.current
	if game == null:
		return
	if homing_id >= 0:
		_step_homing(delta, is_server, game)
	else:
		_step_linear(delta, is_server, game)


func _step_linear(delta: float, is_server: bool, game: Game) -> void:
	var step: float = speed * delta
	var from: Vector3 = global_position
	global_position = from + direction * step
	_traveled += step
	if is_server:
		_check_hits(from, global_position, game)
	if not _finished and _traveled >= max_range:
		_finish()


func _step_homing(delta: float, is_server: bool, game: Game) -> void:
	var target: Entity = game.get_entity(homing_id)
	var target_alive: bool = target != null and not target.dead
	if target_alive:
		_last_target_point = target.global_position + Vector3(0.0, target.bar_height * 0.4, 0.0)
	var to_target: Vector3 = _last_target_point - global_position
	var distance: float = to_target.length()
	var step: float = speed * delta
	if distance <= step + 0.05:
		global_position = _last_target_point
		if is_server and target_alive and on_hit.is_valid() and (target.status_flags & GameConst.FLAG_UNTARGETABLE) == 0:
			on_hit.call(self, target)
		_finish()
		return
	global_position += to_target / distance * step
	if Vector2(to_target.x, to_target.z).length_squared() > 0.01:
		look_at(global_position + to_target, Vector3.UP)


func _check_hits(from: Vector3, to: Vector3, game: Game) -> void:
	var segment := Vector2(to.x - from.x, to.z - from.z)
	var seg_len_sq: float = maxf(segment.length_squared(), 0.000001)
	var candidates: Array = []
	for entity: Entity in game.all_entities():
		if entity.team == team or hit_ids.has(entity.net_id) or not entity.is_targetable_by(team):
			continue
		if entity.is_structure() and not hits_structures:
			continue
		var rel := Vector2(entity.global_position.x - from.x, entity.global_position.z - from.z)
		var t: float = clampf(rel.dot(segment) / seg_len_sq, 0.0, 1.0)
		var closest: Vector2 = segment * t
		if closest.distance_to(rel) <= hit_radius + entity.radius:
			candidates.append([t, entity])
	if candidates.is_empty():
		return
	candidates.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for candidate: Array in candidates:
		var entity: Entity = candidate[1]
		if hit_ids.has(entity.net_id):
			continue
		hit_ids[entity.net_id] = true
		var destroy: bool = true
		if on_hit.is_valid():
			destroy = bool(on_hit.call(self, entity))
		if destroy:
			global_position = from.lerp(to, float(candidate[0]))
			_finish()
			return


func _finish() -> void:
	_finished = true
	if multiplayer.is_server():
		queue_free()
	else:
		visible = false
