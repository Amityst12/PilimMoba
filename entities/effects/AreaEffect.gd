class_name AreaEffect
extends Node3D
## Networked ground area: telegraph during `delay`, then detonates `ticks` times.
## The server applies gameplay in `on_tick`; every peer plays the same visuals from spawn data.

var net_id: int = 0
var style: String = ""
var radius: float = 3.0
var delay: float = 0.5
var ticks: int = 1
var interval: float = 0.5
var team: int = GameConst.TEAM_NONE
var tint: Color = Color(1.0, 0.5, 0.2)

## Server-only: func(effect: AreaEffect, tick_index: int) -> void
var on_tick: Callable

var _elapsed: float = 0.0
var _tick_index: int = 0
var _server_done: bool = false
var _telegraph: MeshInstance3D
var _telegraph_material: ShaderMaterial
var _field: MeshInstance3D


func setup(data: Dictionary) -> void:
	net_id = int(data.get("id", 0))
	style = String(data.get("style", ""))
	position = data.get("pos", Vector3.ZERO)
	radius = float(data.get("radius", 3.0))
	delay = float(data.get("delay", 0.5))
	ticks = maxi(1, int(data.get("ticks", 1)))
	interval = float(data.get("interval", 0.5))
	team = int(data.get("team", 0))
	tint = data.get("color", Color(1.0, 0.5, 0.2))


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var enemy_view: bool = Game.current != null and Game.current.local_team() != team
	var telegraph_color: Color = GameConst.COLOR_RED.lerp(tint, 0.35) if enemy_view else tint
	_telegraph = Fx.ground_decal(self, radius, Fx.SHAPE_DISC, Color(telegraph_color, 0.85))
	_telegraph_material = _telegraph.material_override as ShaderMaterial
	_telegraph_material.set_shader_parameter("fill_alpha", 0.12)
	_telegraph_material.set_shader_parameter("progress_alpha", 0.3)
	if ticks > 1:
		_field = Fx.ground_decal(self, radius, Fx.SHAPE_DISC, Color(tint, 0.35))
		_field.visible = false


func total_duration() -> float:
	return delay + interval * float(ticks - 1)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	while _tick_index < ticks and _elapsed >= delay + interval * float(_tick_index):
		if multiplayer.is_server() and on_tick.is_valid() and Game.current and Game.current.is_playing():
			on_tick.call(self, _tick_index)
		_play_tick_visual(_tick_index)
		_tick_index += 1
	if _elapsed >= total_duration() + 0.5:
		if multiplayer.is_server():
			if not _server_done:
				_server_done = true
				queue_free()
		else:
			visible = false


func _process(_delta: float) -> void:
	if _telegraph_material == null:
		return
	if _tick_index == 0:
		var t: float = clampf(_elapsed / maxf(delay, 0.001), 0.0, 1.0)
		_telegraph_material.set_shader_parameter("progress", t)
	else:
		var fade: float = clampf(1.0 - (_elapsed - total_duration()) / 0.35, 0.0, 1.0)
		_telegraph.visible = ticks > 1 and _elapsed < total_duration()
		if _field:
			_field.visible = fade > 0.0
			(_field.material_override as ShaderMaterial).set_shader_parameter("color", Color(tint, 0.35 * fade))


func _play_tick_visual(index: int) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var parent: Node = Game.current.local_fx_root() if Game.current else get_parent()
	var world_pos: Vector3 = global_position
	match style:
		"arrow_storm":
			Fx.arrow_rain(parent, world_pos, radius, tint)
		_:
			Fx.shockwave(parent, world_pos, radius, tint)
	if index == 0 and Game.current:
		Game.current.shake_camera_at(world_pos, 0.25 if radius < 4.0 else 0.4)
