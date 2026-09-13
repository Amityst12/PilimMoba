class_name UICursor
extends RefCounted
## Custom mouse cursors drawn procedurally (default gold arrow, red sword for attacks).

static var _default_tex: ImageTexture
static var _attack_tex: ImageTexture
static var _current: int = -1


static func set_attack(attack: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode: int = 1 if attack else 0
	if mode == _current:
		return
	_current = mode
	if _default_tex == null:
		_default_tex = ImageTexture.create_from_image(_draw_arrow(Color(0.98, 0.82, 0.42), Color(0.2, 0.13, 0.05)))
		_attack_tex = ImageTexture.create_from_image(_draw_arrow(Color(1.0, 0.36, 0.3), Color(0.25, 0.03, 0.02)))
	Input.set_custom_mouse_cursor(_attack_tex if attack else _default_tex, Input.CURSOR_ARROW, Vector2(1, 1))


static func _draw_arrow(fill: Color, outline: Color) -> Image:
	var size: int = 32
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	# Arrow polygon (tip at 1,1).
	var poly := PackedVector2Array([Vector2(1, 1), Vector2(1, 24), Vector2(7, 18), Vector2(12, 28), Vector2(16, 26), Vector2(11, 16), Vector2(19, 16)])
	for y: int in range(size):
		for x: int in range(size):
			var p := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(p, poly):
				var edge: float = INF
				for i: int in range(poly.size()):
					var a: Vector2 = poly[i]
					var b: Vector2 = poly[(i + 1) % poly.size()]
					edge = minf(edge, Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p))
				var shade: float = 1.0 - float(y) / float(size) * 0.35
				image.set_pixel(x, y, outline if edge < 1.6 else Color(fill.r * shade, fill.g * shade, fill.b * shade, 1.0))
	return image
