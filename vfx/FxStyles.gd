class_name FxStyles
extends RefCounted
## Visual presets for projectiles, keyed by style id (AbilityData.fx_style / attack styles).


static func build_projectile_visual(projectile: Node3D, style: String, tint: Color, team: int) -> void:
	if Fx.is_headless():
		return
	var team_color: Color = GameConst.team_color(team)
	match style:
		"arcane_bolt":
			_orb(projectile, 0.34, tint, true, true)
		"piercing_arrow":
			_arrow(projectile, 1.5, tint, true, 0.09)
		"volley_arrow":
			_arrow(projectile, 0.9, tint, true, 0.06)
		"shield_throw":
			_disc(projectile, 0.55, tint)
		"caster_minion":
			_orb(projectile, 0.15, team_color.lightened(0.2), false, true)
		"tower_shot":
			_orb(projectile, 0.38, team_color.lightened(0.35), true, true)
		"arcanist_attack":
			_orb(projectile, 0.2, Color(0.7, 0.55, 1.0), false, true)
		"ranger_attack":
			_arrow(projectile, 0.8, Color(1.0, 0.9, 0.6), false, 0.05)
		_:
			_orb(projectile, 0.22, tint, false, true)


static func _orb(parent: Node3D, radius: float, color: Color, with_light: bool, with_trail: bool) -> void:
	var core := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	core.mesh = mesh
	core.material_override = Fx.emissive_material(color.lightened(0.25), 5.0)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(core)
	var halo := MeshInstance3D.new()
	var halo_mesh := SphereMesh.new()
	halo_mesh.radius = radius * 1.8
	halo_mesh.height = radius * 3.6
	halo_mesh.radial_segments = 12
	halo_mesh.rings = 6
	halo.mesh = halo_mesh
	halo.material_override = Fx.glow_material(Color(color, 0.35))
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(halo)
	if with_trail:
		_trail(parent, color, radius * 0.6)
	if with_light:
		var light := OmniLight3D.new()
		light.light_color = color
		light.light_energy = 2.5
		light.omni_range = 4.0
		parent.add_child(light)


static func _arrow(parent: Node3D, length: float, color: Color, with_trail: bool, thickness: float) -> void:
	var shaft := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(thickness, thickness, length)
	shaft.mesh = box
	shaft.material_override = Fx.emissive_material(color, 3.0)
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(shaft)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = thickness * 2.2
	head_mesh.height = thickness * 4.4
	head.mesh = head_mesh
	head.position = Vector3(0.0, 0.0, -length * 0.5)
	head.material_override = Fx.emissive_material(color.lightened(0.5), 6.0)
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(head)
	if with_trail:
		_trail(parent, color, thickness * 1.5)


static func _disc(parent: Node3D, radius: float, color: Color) -> void:
	var disc := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.12
	disc.mesh = mesh
	disc.material_override = Fx.emissive_material(color, 3.0)
	parent.add_child(disc)
	_trail(parent, color, 0.12)


static func _trail(parent: Node3D, color: Color, size: float) -> void:
	var particles := CPUParticles3D.new()
	particles.amount = 24
	particles.lifetime = 0.3
	particles.local_coords = false
	particles.gravity = Vector3.ZERO
	particles.direction = Vector3(0.0, 0.0, 1.0)
	particles.spread = 25.0
	particles.initial_velocity_min = 0.2
	particles.initial_velocity_max = 0.8
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	particles.scale_amount_curve = curve
	var mesh := SphereMesh.new()
	mesh.radius = maxf(size, 0.04)
	mesh.height = maxf(size, 0.04) * 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	mesh.material = Fx.glow_material(Color(color.r * 1.4, color.g * 1.4, color.b * 1.4, 0.8))
	particles.mesh = mesh
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(particles)
