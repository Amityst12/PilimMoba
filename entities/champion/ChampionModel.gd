class_name ChampionModel
extends Node3D
## Procedural animation for primitive champion models: idle breathing, walk bounce,
## orbiting accessories, and dynamic auto-attack strikes.

@export var bob_height: float = 0.07
@export var walk_frequency: float = 11.0
@export var orbit_speed: float = 2.2

var _time: float = randf() * 10.0
var _orbit: Node3D
var _attack_timer: float = 0.0
var _attack_duration: float = 0.25
var _is_ranged: bool = false
var _attack_flip: float = 1.0


func _ready() -> void:
	_orbit = get_node_or_null("Orbit") as Node3D


func trigger_attack(is_ranged: bool = false, duration: float = 0.26) -> void:
	_is_ranged = is_ranged
	_attack_duration = clampf(duration, 0.15, 0.45)
	_attack_timer = _attack_duration
	_attack_flip = -_attack_flip


func _process(delta: float) -> void:
	var entity := get_parent().get_parent() as Entity
	var moving: bool = entity != null and entity.net_velocity.length_squared() > 0.6
	_time += delta

	# Base locomotion (bobbing & pitch)
	var base_y: float
	var base_rot_x: float
	if moving:
		base_y = absf(sin(_time * walk_frequency)) * bob_height
		base_rot_x = -0.06
	else:
		base_y = sin(_time * 2.0) * 0.015
		base_rot_x = 0.0

	# Auto-attack procedural strike animation
	if _attack_timer > 0.0:
		_attack_timer = maxf(0.0, _attack_timer - delta)
		var progress: float = 1.0 - (_attack_timer / _attack_duration)
		var strike: float = sin(progress * PI)

		if _is_ranged:
			# Ranged recoil and projectile release snap
			position.z = -strike * 0.22
			position.y = base_y + strike * 0.04
			rotation.x = base_rot_x - strike * 0.2
			rotation.y = lerpf(rotation.y, 0.0, delta * 12.0)
			scale = Vector3(1.0 + strike * 0.12, 1.0 - strike * 0.06, 1.0 + strike * 0.08)
		else:
			# Melee lunge, forward tilt, and alternating swing
			position.z = -strike * 0.42
			position.y = base_y + strike * 0.08
			rotation.x = base_rot_x - strike * 0.38
			rotation.y = strike * 0.28 * _attack_flip
			scale = Vector3(1.0 + strike * 0.14, 1.0 - strike * 0.08, 1.0 + strike * 0.25)
	else:
		position.y = base_y
		position.z = lerpf(position.z, 0.0, delta * 12.0)
		rotation.x = lerpf(rotation.x, base_rot_x, delta * 8.0)
		rotation.y = lerpf(rotation.y, 0.0, delta * 12.0)
		scale = scale.lerp(Vector3.ONE, delta * 12.0)

	if _orbit:
		_orbit.rotation.y += orbit_speed * delta
