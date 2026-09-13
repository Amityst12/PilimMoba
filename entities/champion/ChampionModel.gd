class_name ChampionModel
extends Node3D
## Procedural animation for primitive champion models: idle breathing, walk bounce,
## orbiting accessories. Attach to the root of a champion model scene.

@export var bob_height: float = 0.07
@export var walk_frequency: float = 11.0
@export var orbit_speed: float = 2.2

var _time: float = randf() * 10.0
var _orbit: Node3D


func _ready() -> void:
	_orbit = get_node_or_null("Orbit") as Node3D


func _process(delta: float) -> void:
	var entity := get_parent().get_parent() as Entity
	var moving: bool = entity != null and entity.net_velocity.length_squared() > 0.6
	_time += delta
	if moving:
		position.y = absf(sin(_time * walk_frequency)) * bob_height
		rotation.x = -0.06
	else:
		position.y = sin(_time * 2.0) * 0.015
		rotation.x = lerpf(rotation.x, 0.0, delta * 8.0)
	if _orbit:
		_orbit.rotation.y += orbit_speed * delta
