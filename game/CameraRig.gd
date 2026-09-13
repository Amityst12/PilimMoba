class_name CameraRig
extends Node3D
## MOBA camera: locked follow (default) or free edge-panning, zoom, and trauma-based shake.

@export var pitch_degrees: float = 57.0
@export var min_distance: float = 17.0
@export var max_distance: float = 36.0
@export var edge_pan_speed: float = 34.0
@export var edge_margin: float = 12.0

var distance: float = 27.0
var target_distance: float = 27.0
var focus: Vector3 = Vector3.ZERO
var locked: bool = true
var follow_target: Node3D
var edge_pan_enabled: bool = true

var _trauma: float = 0.0
var _noise_time: float = 0.0

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	locked = Settings.camera_locked
	_apply(Vector3.ZERO)


func snap_to(point: Vector3) -> void:
	focus = Vector3(point.x, 0.0, point.z)
	_apply(Vector3.ZERO)


func zoom(steps: float) -> void:
	target_distance = clampf(target_distance + steps * 2.2, min_distance, max_distance)


func add_trauma(amount: float) -> void:
	if Settings.screen_shake:
		_trauma = minf(1.0, _trauma + amount)


func toggle_lock() -> void:
	locked = not locked
	Settings.camera_locked = locked
	Settings.save_settings()


func _process(delta: float) -> void:
	var following: bool = follow_target != null and is_instance_valid(follow_target) \
			and (locked or Input.is_action_pressed("camera_center"))
	if following:
		var target := Vector3(follow_target.global_position.x, 0.0, follow_target.global_position.z)
		focus = focus.lerp(target, 1.0 - exp(-delta * 12.0))
	else:
		var pan := Vector2.ZERO
		if edge_pan_enabled and DisplayServer.window_is_focused() and get_viewport().gui_get_focus_owner() == null:
			var mouse: Vector2 = get_viewport().get_mouse_position()
			var size: Vector2 = get_viewport().get_visible_rect().size
			if Rect2(Vector2.ZERO, size).has_point(mouse):
				if mouse.x < edge_margin:
					pan.x -= 1.0
				elif mouse.x > size.x - edge_margin:
					pan.x += 1.0
				if mouse.y < edge_margin:
					pan.y -= 1.0
				elif mouse.y > size.y - edge_margin:
					pan.y += 1.0
		pan += Input.get_vector("cam_left", "cam_right", "cam_up", "cam_down")
		if pan != Vector2.ZERO:
			focus += Vector3(pan.x, 0.0, pan.y).normalized() * edge_pan_speed * delta * (distance / 27.0)
	focus.x = clampf(focus.x, -Arena.HALF_X, Arena.HALF_X)
	focus.z = clampf(focus.z, -Arena.HALF_Z + 4.0, Arena.HALF_Z + 2.0)
	distance = lerpf(distance, target_distance, 1.0 - exp(-delta * 10.0))

	var shake := Vector3.ZERO
	if _trauma > 0.0:
		_noise_time += delta * 40.0
		var amount: float = _trauma * _trauma
		shake = Vector3(sin(_noise_time * 1.3), 0.0, cos(_noise_time * 1.7)) * amount * 0.6
		_trauma = maxf(0.0, _trauma - delta * 1.8)
	_apply(shake)


func _apply(shake: Vector3) -> void:
	if camera == null:
		return
	var pitch: float = deg_to_rad(pitch_degrees)
	var offset := Vector3(0.0, sin(pitch), cos(pitch)) * distance
	camera.global_position = focus + offset + shake
	camera.look_at(focus + shake, Vector3.UP)


## Projects a screen position onto the ground plane (y = 0).
func screen_to_ground(screen_position: Vector2) -> Vector3:
	if camera == null:
		return focus
	var origin: Vector3 = camera.project_ray_origin(screen_position)
	var direction: Vector3 = camera.project_ray_normal(screen_position)
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)
	if hit == null:
		return focus
	return hit as Vector3


func mouse_ground_position() -> Vector3:
	return screen_to_ground(get_viewport().get_mouse_position())


## Ground-plane corners of the visible area (for the minimap view box).
func visible_ground_quad() -> PackedVector3Array:
	var size: Vector2 = get_viewport().get_visible_rect().size
	return PackedVector3Array([
		screen_to_ground(Vector2.ZERO), screen_to_ground(Vector2(size.x, 0.0)),
		screen_to_ground(size), screen_to_ground(Vector2(0.0, size.y)),
	])
