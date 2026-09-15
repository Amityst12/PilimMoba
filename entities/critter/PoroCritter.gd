class_name PoroCritter
extends Node3D
## ARAM Bridge Poro / Pilim Critter.
## Cute fluffy companion that wanders along the Howling Abyss bridge,
## hops curiously, reacts to nearby champions, and grows with hearts when fed!

var _time: float = randf() * 10.0
var _hop_offset: float = randf() * 5.0
var _wander_dir: Vector3 = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-0.5, 0.5)).normalized()
var _scale_mult: float = 1.0
var _scared_timer: float = 0.0

@onready var visual: Node3D = $Visual
@onready var body: MeshInstance3D = $Visual/Body
@onready var heart_light: OmniLight3D = $Visual/HeartLight


func _ready() -> void:
	_time += randf() * 5.0


func _process(delta: float) -> void:
	_time += delta
	var hop: float = absf(sin(_time * 5.0 + _hop_offset)) * 0.28
	if visual:
		visual.position.y = hop
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(_wander_dir.x, _wander_dir.z), delta * 4.0)

	# Wander slowly along bridge
	global_position += _wander_dir * (delta * 1.2)
	# Bridge boundaries clamp
	global_position.x = clampf(global_position.x, -45.0, 45.0)
	global_position.z = clampf(global_position.z, -5.5, 5.5)

	# Periodic turn
	if fmod(_time, 3.5) < delta:
		_wander_dir = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-0.8, 0.8)).normalized()

	# Champion proximity reaction
	var game := Game.current
	if game:
		for champ: Champion in game.champions:
			if champ.dead:
				continue
			var d := planar_distance_to(champ.global_position)
			if d < 3.2:
				var away := (global_position - champ.global_position).normalized()
				away.y = 0.0
				_wander_dir = away
				break


func planar_distance_to(pos: Vector3) -> float:
	return Vector2(global_position.x - pos.x, global_position.z - pos.z).length()


func feed_snax() -> void:
	_scale_mult = minf(_scale_mult + 0.25, 2.2)
	scale = Vector3.ONE * _scale_mult
	if heart_light:
		heart_light.visible = true
	var game := Game.current
	if game:
		game.play_fx("sparkle", global_position + Vector3(0.0, 0.8, 0.0), {"color": Color(1.0, 0.4, 0.6)})
	Sfx.play("powerup", -4.0, 0.2)
