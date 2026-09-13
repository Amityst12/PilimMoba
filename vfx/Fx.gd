class_name Fx
extends RefCounted
## Client-side visual effect helpers (particles, decals, lights, floating text).
## All effects are cosmetic and self-freeing. Never used for gameplay logic.

const SHAPE_RING: int = 0
const SHAPE_DISC: int = 1
const SHAPE_RECT: int = 2
const SHAPE_SKILLSHOT: int = 3
const DECAL_HEIGHT: float = 0.04

static var _decal_shader: Shader
static var _materials: Dictionary = {}
static var _sphere_mesh: SphereMesh
static var _quad_mesh: QuadMesh


static func is_headless() -> bool:
	return DisplayServer.get_name() == "headless"


static func decal_shader() -> Shader:
	if _decal_shader == null:
		_decal_shader = load("res://assets/shaders/ground_decal.gdshader") as Shader
	return _decal_shader


## Horizontal circular decal (ring or disc) centered on the parent.
static func ground_decal(parent: Node, radius: float, shape: int, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(radius * 2.0, radius * 2.0)
	mesh_instance.mesh = plane
	mesh_instance.position.y = DECAL_HEIGHT
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = decal_shader()
	material.set_shader_parameter("color", color)
	material.set_shader_parameter("shape", shape)
	material.set_shader_parameter("edge_width", clampf(0.12 / maxf(radius, 0.1), 0.01, 0.4))
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance


## Rectangle decal starting at the parent origin and extending along local -Z.
static func ground_rect(parent: Node, width: float, length: float, color: Color, shape: int = SHAPE_RECT) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(width, length)
	mesh_instance.mesh = plane
	mesh_instance.position = Vector3(0.0, DECAL_HEIGHT, -length * 0.5)
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = decal_shader()
	material.set_shader_parameter("color", color)
	material.set_shader_parameter("shape", shape)
	material.set_shader_parameter("edge_width", clampf(0.16 / maxf(width * 0.5, 0.1), 0.02, 0.5))
	material.set_shader_parameter("end_width", clampf(0.16 / maxf(length, 0.1), 0.002, 0.2))
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance


static func glow_material(color: Color, additive: bool = true) -> StandardMaterial3D:
	var key: String = "%s_%s" % [color.to_html(true), additive]
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = color
	material.vertex_color_use_as_albedo = true
	material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = material
	return material


static func emissive_material(color: Color, energy: float = 2.5) -> StandardMaterial3D:
	var key: String = "emissive_%s_%.2f" % [color.to_html(false), energy]
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	_materials[key] = material
	return material


static func sphere_mesh() -> SphereMesh:
	if _sphere_mesh == null:
		_sphere_mesh = SphereMesh.new()
		_sphere_mesh.radius = 0.5
		_sphere_mesh.height = 1.0
		_sphere_mesh.radial_segments = 12
		_sphere_mesh.rings = 6
	return _sphere_mesh


static func _auto_free(node: Node, lifetime: float) -> void:
	if node.is_inside_tree():
		node.get_tree().create_timer(lifetime, false).timeout.connect(node.queue_free)


## One-shot particle burst.
static func burst(parent: Node, pos: Vector3, color: Color, amount: int = 16, speed: float = 4.0,
		lifetime: float = 0.45, size: float = 0.15, gravity: float = -4.0) -> void:
	if parent == null or is_headless():
		return
	var particles := CPUParticles3D.new()
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.amount = maxi(1, amount)
	particles.lifetime = lifetime
	particles.direction = Vector3.UP
	particles.spread = 180.0
	particles.initial_velocity_min = speed * 0.4
	particles.initial_velocity_max = speed
	particles.gravity = Vector3(0.0, gravity, 0.0)
	particles.damping_min = 2.0
	particles.damping_max = 4.0
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.0
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	particles.scale_amount_curve = curve
	var mesh := SphereMesh.new()
	mesh.radius = size
	mesh.height = size * 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	mesh.material = glow_material(Color(color.r * 1.6, color.g * 1.6, color.b * 1.6, 1.0))
	particles.mesh = mesh
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(particles)
	particles.global_position = pos
	particles.emitting = true
	_auto_free(particles, lifetime + 0.2)


static func flash_light(parent: Node, pos: Vector3, color: Color, energy: float = 4.0, light_range: float = 6.0,
		duration: float = 0.35) -> void:
	if parent == null or is_headless():
		return
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	parent.add_child(light)
	light.global_position = pos + Vector3(0.0, 1.2, 0.0)
	var tween: Tween = light.create_tween()
	tween.tween_property(light, "light_energy", 0.0, duration)
	tween.tween_callback(light.queue_free)


## Expanding ground ring + particles + light flash.
static func shockwave(parent: Node, pos: Vector3, radius: float, color: Color) -> void:
	if parent == null or is_headless():
		return
	var holder := Node3D.new()
	parent.add_child(holder)
	holder.global_position = Vector3(pos.x, 0.0, pos.z)
	var ring: MeshInstance3D = ground_decal(holder, radius, SHAPE_RING, Color(color.lightened(0.3), 1.0))
	var material: ShaderMaterial = ring.material_override
	material.set_shader_parameter("edge_width", 0.18)
	ring.scale = Vector3(0.3, 1.0, 0.3)
	var disc: MeshInstance3D = ground_decal(holder, radius, SHAPE_DISC, Color(color, 0.6))
	var disc_material: ShaderMaterial = disc.material_override
	disc_material.set_shader_parameter("fill_alpha", 0.55)
	var tween: Tween = holder.create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(1.05, 1.0, 1.05), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(a: float) -> void: material.set_shader_parameter("color", Color(color.lightened(0.3), a)), 1.0, 0.0, 0.45)
	tween.tween_method(func(a: float) -> void: disc_material.set_shader_parameter("color", Color(color, a)), 0.6, 0.0, 0.35)
	tween.chain().tween_callback(holder.queue_free)
	burst(parent, pos + Vector3(0.0, 0.3, 0.0), color, int(10 + radius * 6.0), 3.0 + radius * 1.5, 0.5, 0.14, -6.0)
	flash_light(parent, pos, color, 5.0, radius * 2.5, 0.35)


static func arrow_rain(parent: Node, pos: Vector3, radius: float, color: Color) -> void:
	if parent == null or is_headless():
		return
	for i: int in range(10):
		var streak := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.06, 1.4, 0.06)
		streak.mesh = box
		streak.material_override = glow_material(Color(color.r * 1.8, color.g * 1.8, color.b * 1.8, 0.9))
		streak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(streak)
		var angle: float = randf() * TAU
		var dist: float = sqrt(randf()) * radius * 0.9
		var ground := Vector3(pos.x + cos(angle) * dist, 0.0, pos.z + sin(angle) * dist)
		streak.global_position = ground + Vector3(0.6, 7.0, 0.3)
		streak.rotation = Vector3(0.0, 0.0, -0.08)
		var delay: float = randf() * 0.2
		var tween: Tween = streak.create_tween()
		tween.tween_interval(delay)
		tween.tween_property(streak, "global_position", ground + Vector3(0.0, 0.5, 0.0), 0.16)
		tween.tween_callback(func() -> void: burst(parent, ground + Vector3(0.0, 0.2, 0.0), color, 5, 2.5, 0.3, 0.08, -8.0))
		tween.tween_callback(streak.queue_free)
	var holder := Node3D.new()
	parent.add_child(holder)
	holder.global_position = Vector3(pos.x, 0.0, pos.z)
	var disc: MeshInstance3D = ground_decal(holder, radius, SHAPE_DISC, Color(color, 0.5))
	var disc_material: ShaderMaterial = disc.material_override
	disc_material.set_shader_parameter("fill_alpha", 0.35)
	var fade: Tween = holder.create_tween()
	fade.tween_method(func(a: float) -> void: disc_material.set_shader_parameter("color", Color(color, a)), 0.5, 0.0, 0.4)
	fade.tween_callback(holder.queue_free)


## Vertical light column (blink, respawn, recall arrival).
static func pillar(parent: Node, pos: Vector3, color: Color, height: float = 4.0, duration: float = 0.5) -> void:
	if parent == null or is_headless():
		return
	var column := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.25
	cylinder.bottom_radius = 0.9
	cylinder.height = height
	cylinder.cap_top = false
	cylinder.cap_bottom = false
	column.mesh = cylinder
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(color.lightened(0.4), 0.8)
	column.material_override = material
	column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(column)
	column.global_position = pos + Vector3(0.0, height * 0.5, 0.0)
	var tween: Tween = column.create_tween().set_parallel(true)
	tween.tween_property(column, "scale", Vector3(0.2, 1.3, 0.2), duration).set_ease(Tween.EASE_IN)
	tween.tween_property(material, "albedo_color:a", 0.0, duration)
	tween.chain().tween_callback(column.queue_free)
	burst(parent, pos + Vector3(0.0, 0.8, 0.0), color, 18, 3.5, 0.5, 0.1, 3.0)


## Floating combat text (damage numbers, gold, level up).
static func floating_text(parent: Node, pos: Vector3, text: String, color: Color, font_size: int = 40,
		rise: float = 1.6, duration: float = 0.9) -> void:
	if parent == null or is_headless():
		return
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.outline_size = 10
	label.modulate = color
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = false
	label.pixel_size = 0.0065
	label.render_priority = 10
	label.outline_render_priority = 9
	parent.add_child(label)
	var jitter := Vector3(randf_range(-0.35, 0.35), 0.0, randf_range(-0.2, 0.2))
	label.global_position = pos + jitter
	label.scale = Vector3.ONE * 0.6
	var tween: Tween = label.create_tween().set_parallel(true)
	tween.tween_property(label, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "global_position", label.global_position + Vector3(0.0, rise, 0.0), duration) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6)
	tween.tween_property(label, "outline_modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6)
	tween.chain().tween_callback(label.queue_free)


static func click_marker(parent: Node, pos: Vector3, color: Color) -> void:
	if parent == null or is_headless():
		return
	var holder := Node3D.new()
	parent.add_child(holder)
	holder.global_position = Vector3(pos.x, 0.0, pos.z)
	var ring: MeshInstance3D = ground_decal(holder, 0.7, SHAPE_RING, color)
	var material: ShaderMaterial = ring.material_override
	material.set_shader_parameter("edge_width", 0.3)
	holder.scale = Vector3(1.4, 1.0, 1.4)
	var tween: Tween = holder.create_tween().set_parallel(true)
	tween.tween_property(holder, "scale", Vector3(0.35, 1.0, 0.35), 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(a: float) -> void: material.set_shader_parameter("color", Color(color, a)), color.a, 0.0, 0.35)
	tween.chain().tween_callback(holder.queue_free)


static func ping_marker(parent: Node, pos: Vector3, type: int, color: Color) -> void:
	if parent == null or is_headless():
		return
	var holder := Node3D.new()
	parent.add_child(holder)
	holder.global_position = Vector3(pos.x, 0.0, pos.z)

	# Expanding ground ring
	var ring: MeshInstance3D = ground_decal(holder, 1.8, SHAPE_RING, color)
	var material: ShaderMaterial = ring.material_override
	material.set_shader_parameter("edge_width", 0.22)
	ring.scale = Vector3(0.2, 1.0, 0.2)

	# Vertical beacon pillar
	var column := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.08
	cylinder.bottom_radius = 0.35
	cylinder.height = 3.2
	column.mesh = cylinder
	var col_mat := glow_material(Color(color, 0.75))
	column.material_override = col_mat
	holder.add_child(column)
	column.position = Vector3(0.0, 1.6, 0.0)

	# Floating billboard text label
	var label := Label3D.new()
	label.text = GameConst.ping_label(type).to_upper()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = color
	label.outline_modulate = Color(0.05, 0.05, 0.08, 0.95)
	label.outline_size = 10
	label.font_size = 42
	label.pixel_size = 0.009
	label.position = Vector3(0.0, 3.4, 0.0)
	holder.add_child(label)

	var tween: Tween = holder.create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(1.3, 1.0, 1.3), 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(column, "scale", Vector3(0.25, 1.2, 0.25), 2.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(label, "position:y", 4.0, 2.2).set_trans(Tween.TRANS_SINE)
	tween.tween_method(func(a: float) -> void: material.set_shader_parameter("color", Color(color, a)), 1.0, 0.0, 0.6).set_delay(1.6)
	tween.tween_property(col_mat, "albedo_color:a", 0.0, 0.6).set_delay(1.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(1.6)
	tween.chain().tween_callback(holder.queue_free)

	flash_light(parent, pos, color, 4.0, 6.0, 0.4)


## Dispatches a named effect (used by Game._rpc_fx).
static func play(kind: String, parent: Node, pos: Vector3, params: Dictionary) -> void:
	if parent == null or is_headless():
		return
	var color: Color = params.get("color", Color.WHITE)
	match kind:
		"hit":
			burst(parent, pos, color, 12, 4.5, 0.35, 0.12)
			flash_light(parent, pos, color, 2.5, 3.5, 0.2)
		"impact":
			shockwave(parent, pos, float(params.get("radius", 1.5)), color)
		"blink":
			pillar(parent, pos, color, 3.5, 0.45)
			flash_light(parent, pos, color, 4.0, 5.0, 0.35)
		"dash":
			burst(parent, pos + Vector3(0.0, 0.3, 0.0), Color(0.8, 0.75, 0.65), 14, 3.0, 0.45, 0.16, -2.0)
		"buff":
			burst(parent, pos + Vector3(0.0, 0.5, 0.0), color, 22, 3.0, 0.7, 0.1, 5.0)
			flash_light(parent, pos, color, 3.0, 4.0, 0.4)
		"levelup":
			pillar(parent, pos, GameConst.COLOR_GOLD, 5.0, 0.8)
			burst(parent, pos + Vector3(0.0, 1.0, 0.0), GameConst.COLOR_GOLD, 30, 4.0, 0.9, 0.1, 3.0)
		"explosion":
			shockwave(parent, pos, float(params.get("radius", 5.0)), color)
			burst(parent, pos + Vector3(0.0, 2.0, 0.0), Color(1.0, 0.6, 0.25), 60, 9.0, 1.2, 0.3, -9.0)
			flash_light(parent, pos, Color(1.0, 0.7, 0.3), 12.0, 18.0, 0.9)
		"death":
			burst(parent, pos + Vector3(0.0, 1.0, 0.0), color, 24, 5.0, 0.7, 0.14, -8.0)
		_:
			burst(parent, pos, color)
