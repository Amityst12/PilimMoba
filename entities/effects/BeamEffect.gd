class_name BeamEffect
extends Node3D
## Networked beam: charges (telegraph rectangle) then fires along a direction.

var net_id: int = 0
var style: String = ""
var direction: Vector3 = Vector3.FORWARD
var length: float = 18.0
var width: float = 3.0
var charge: float = 0.6
var team: int = GameConst.TEAM_NONE
var tint: Color = Color(1.0, 0.3, 0.5)

## Server-only: func(beam: BeamEffect) -> void
var on_fire: Callable

var _elapsed: float = 0.0
var _fired: bool = false
var _server_done: bool = false
var _telegraph_material: ShaderMaterial
var _telegraph: MeshInstance3D
var _beam: MeshInstance3D
var _beam_material: StandardMaterial3D
var _light: OmniLight3D

const LINGER: float = 0.55


func setup(data: Dictionary) -> void:
	net_id = int(data.get("id", 0))
	style = String(data.get("style", ""))
	position = data.get("pos", Vector3.ZERO)
	direction = (data.get("dir", Vector3.FORWARD) as Vector3).normalized()
	length = float(data.get("length", 18.0))
	width = float(data.get("width", 3.0))
	charge = float(data.get("charge", 0.6))
	team = int(data.get("team", 0))
	tint = data.get("color", Color(1.0, 0.3, 0.5))


func _ready() -> void:
	rotation.y = atan2(-direction.x, -direction.z)
	if DisplayServer.get_name() == "headless":
		return
	var enemy_view: bool = Game.current != null and Game.current.local_team() != team
	var telegraph_color: Color = GameConst.COLOR_RED.lerp(tint, 0.3) if enemy_view else tint
	_telegraph = Fx.ground_rect(self, width, length, Color(telegraph_color, 0.9))
	_telegraph_material = _telegraph.material_override as ShaderMaterial
	_telegraph_material.set_shader_parameter("fill_alpha", 0.1)
	_telegraph_material.set_shader_parameter("progress_alpha", 0.35)

	_beam = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(width * 0.8, 1.4, length)
	_beam.mesh = box
	_beam.position = Vector3(0.0, 1.1, -length * 0.5)
	_beam_material = StandardMaterial3D.new()
	_beam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beam_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_beam_material.albedo_color = Color(tint.lightened(0.4), 0.0)
	_beam_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_beam.material_override = _beam_material
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_beam.visible = false
	add_child(_beam)

	_light = OmniLight3D.new()
	_light.light_color = tint
	_light.omni_range = 6.0
	_light.light_energy = 0.0
	_light.position = Vector3(0.0, 1.5, -1.0)
	add_child(_light)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if not _fired and _elapsed >= charge:
		_fired = true
		if multiplayer.is_server() and on_fire.is_valid() and Game.current and Game.current.is_playing():
			on_fire.call(self)
		_play_fire_visual()
	if _elapsed >= charge + LINGER:
		if multiplayer.is_server():
			if not _server_done:
				_server_done = true
				queue_free()
		else:
			visible = false


func _process(_delta: float) -> void:
	if _telegraph_material == null:
		return
	if not _fired:
		var t: float = clampf(_elapsed / maxf(charge, 0.001), 0.0, 1.0)
		_telegraph_material.set_shader_parameter("progress", t)
		_light.light_energy = t * 2.0
	else:
		var fade: float = clampf(1.0 - (_elapsed - charge) / LINGER, 0.0, 1.0)
		_telegraph.visible = false
		_beam.visible = fade > 0.0
		_beam.scale = Vector3(fade * 0.7 + 0.3, fade, 1.0)
		_beam_material.albedo_color = Color(tint.lightened(0.5), fade * 0.95)
		_light.light_energy = fade * 6.0


func _play_fire_visual() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var parent: Node = Game.current.local_fx_root() if Game.current else get_parent()
	var steps: int = int(length / 2.5)
	for i: int in range(steps + 1):
		var p: Vector3 = global_position + direction * (float(i) / float(maxi(steps, 1)) * length) + Vector3(0.0, 1.0, 0.0)
		Fx.burst(parent, p, tint, 8, 5.0, 0.45, 0.18)
	if Game.current:
		Game.current.shake_camera_at(global_position + direction * length * 0.3, 0.55)
