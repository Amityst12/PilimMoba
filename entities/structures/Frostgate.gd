class_name Frostgate
extends Node3D
## ARAM Frostgate (Hexgate Portal).
## Placed on the base fountain. Stepping onto it channels for 0.5s and launches the
## champion in a high-speed airborne arc straight to the frontline friendly tower.

const GameConst = preload("res://core/GameConst.gd")

@export var team: int = GameConst.TEAM_BLUE
var net_id: int = 0
var is_active: bool = true

var _time: float = 0.0
var _channeling_champs: Dictionary = {}
var _flying_champs: Dictionary = {}

@onready var visual: Node3D = $Visual
@onready var rune_ring: Node3D = $Visual/RuneRing
@onready var vortex: Node3D = $Visual/Vortex
@onready var light: OmniLight3D = $Visual/OmniLight3D


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	_time += delta
	if rune_ring:
		rune_ring.rotation.y += delta * 1.5
	if vortex:
		vortex.rotation.y -= delta * 2.5
		vortex.scale.y = 1.0 + sin(_time * 4.0) * 0.15
	if light:
		light.light_energy = 1.6 + sin(_time * 5.0) * 0.4


func _physics_process(delta: float) -> void:
	_process_flying(delta)

	if not multiplayer.is_server():
		return

	var game := Game.current
	if game == null or game.phase != Game.Phase.PLAYING:
		return

	for champ: Champion in game.champions:
		if champ.dead or champ.team != team:
			continue
		if _flying_champs.has(champ.net_id):
			continue

		var dist: float = Vector2(global_position.x - champ.global_position.x, global_position.z - champ.global_position.z).length()
		if dist <= 2.2:
			_tick_channel(champ, delta, game)
		else:
			if _channeling_champs.has(champ.net_id):
				_channeling_champs.erase(champ.net_id)


func _tick_channel(champ, delta: float, game) -> void:
	var cid: int = champ.net_id
	var elapsed: float = _channeling_champs.get(cid, 0.0) + delta
	_channeling_champs[cid] = elapsed

	if elapsed >= 0.5:
		_channeling_champs.erase(cid)
		_launch_champion(champ, game)


func _launch_champion(champ, game) -> void:
	var land_pos := _get_target_destination(game)
	rpc("_rpc_start_flight", champ.net_id, global_position, land_pos, 2.0)


func _get_target_destination(game) -> Vector3:
	var outer_alive: bool = false
	var sign_x: float = -1.0 if team == GameConst.TEAM_BLUE else 1.0
	for struct in game.structures:
		if struct is Tower and struct.team == team and not struct.dead:
			if absf(struct.global_position.x) < 30.0:
				outer_alive = true
				break

	if outer_alive:
		return Vector3(sign_x * 24.0, 0.0, 0.0)
	else:
		return Vector3(sign_x * 40.0, 0.0, 0.0)


@rpc("call_local", "reliable")
func _rpc_start_flight(champ_id: int, start_pos: Vector3, land_pos: Vector3, duration: float) -> void:
	var game := Game.current
	if game == null:
		return
	var champ: Champion = game.entities.get(champ_id) as Champion
	if champ == null:
		return

	_flying_champs[champ_id] = {
		"champ": champ,
		"start": start_pos,
		"end": land_pos,
		"elapsed": 0.0,
		"duration": duration,
	}
	game.play_fx("sparkle", start_pos + Vector3(0.0, 1.0, 0.0), {"color": Color(0.2, 0.85, 1.0)})
	Sfx.play("spell", -2.0, 0.1)


func _process_flying(delta: float) -> void:
	if _flying_champs.is_empty():
		return

	var finished_ids: Array[int] = []
	for cid: int in _flying_champs.keys():
		var data: Dictionary = _flying_champs[cid]
		var champ: Champion = data["champ"]
		if not is_instance_valid(champ) or champ.dead:
			finished_ids.append(cid)
			continue

		data["elapsed"] += delta
		var t: float = clampf(data["elapsed"] / data["duration"], 0.0, 1.0)

		var start: Vector3 = data["start"]
		var end: Vector3 = data["end"]
		var current_xz := start.lerp(end, t)
		var height: float = sin(t * PI) * 5.5
		champ.global_position = Vector3(current_xz.x, height, current_xz.z)

		if t >= 1.0:
			champ.global_position = end
			finished_ids.append(cid)
			to_flight_landed(champ, end)

	for cid: int in finished_ids:
		_flying_champs.erase(cid)


func to_flight_landed(champ, land_pos: Vector3) -> void:
	var game := Game.current
	if game:
		game.play_fx("impact", land_pos, {"color": Color(0.3, 0.9, 1.0), "radius": 2.5})
	Sfx.play("impact", -4.0)
