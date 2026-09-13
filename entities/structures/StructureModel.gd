class_name StructureModel
extends Node3D
## Procedurally built tower / nexus models with an intact and a destroyed state.

static var _materials: Dictionary = {}

var crystal: Node3D
var intact: Node3D
var rubble: Node3D
var spin_speed: float = 0.8
var bob_amplitude: float = 0.15
var _time: float = randf() * 10.0
var _crystal_base_y: float = 0.0
var _light: OmniLight3D


static func _material(key: String, color: Color, metallic: float = 0.0, roughness: float = 0.8,
		emission: float = 0.0) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	_materials[key] = material
	return material


static func _add(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO,
		scale_vec: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	instance.rotation = rot
	instance.scale = scale_vec
	parent.add_child(instance)
	return instance


static func _cylinder(top: float, bottom: float, height: float, sides: int = 12) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = sides
	return mesh


static func _stone() -> StandardMaterial3D:
	return _material("stone", Color(0.42, 0.43, 0.46), 0.0, 0.9)


static func _dark_stone() -> StandardMaterial3D:
	return _material("dark_stone", Color(0.25, 0.26, 0.3), 0.0, 0.95)


static func _team_glow(team: int, energy: float = 4.0) -> StandardMaterial3D:
	return _material("glow_%d_%.1f" % [team, energy], GameConst.team_color(team).lightened(0.2), 0.0, 0.3, energy)


static func _team_metal(team: int) -> StandardMaterial3D:
	return _material("metal_%d" % team, GameConst.team_color(team).darkened(0.3), 0.7, 0.35)


static func build_tower(team: int) -> StructureModel:
	var model := StructureModel.new()
	model.name = "TowerModel"
	model.intact = Node3D.new()
	model.add_child(model.intact)
	var root: Node3D = model.intact
	_add(root, _cylinder(1.35, 1.55, 0.55, 8), _dark_stone(), Vector3(0.0, 0.27, 0.0))
	_add(root, _cylinder(0.75, 1.0, 3.4, 8), _stone(), Vector3(0.0, 2.2, 0.0))
	_add(root, _cylinder(1.02, 1.02, 0.22, 8), _team_metal(team), Vector3(0.0, 1.2, 0.0))
	_add(root, _cylinder(0.8, 0.8, 0.18, 8), _team_metal(team), Vector3(0.0, 3.2, 0.0))
	_add(root, _cylinder(1.15, 0.85, 0.45, 8), _dark_stone(), Vector3(0.0, 4.1, 0.0))
	for i: int in range(4):
		var angle: float = TAU * float(i) / 4.0 + PI * 0.25
		var spike := BoxMesh.new()
		spike.size = Vector3(0.25, 0.9, 0.25)
		_add(root, spike, _stone(), Vector3(cos(angle) * 0.9, 4.7, sin(angle) * 0.9))
	model.crystal = Node3D.new()
	model.crystal.position = Vector3(0.0, 5.1, 0.0)
	root.add_child(model.crystal)
	var gem := SphereMesh.new()
	gem.radius = 0.42
	gem.height = 0.84
	gem.radial_segments = 8
	gem.rings = 4
	_add(model.crystal, gem, _team_glow(team, 5.0), Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.35, 1.0))
	model._crystal_base_y = 5.1
	model._light = OmniLight3D.new()
	model._light.light_color = GameConst.team_color(team)
	model._light.light_energy = 1.6
	model._light.omni_range = 7.0
	model._light.position = Vector3(0.0, 5.0, 0.0)
	root.add_child(model._light)

	model.rubble = Node3D.new()
	model.rubble.visible = false
	model.add_child(model.rubble)
	_add(model.rubble, _cylinder(1.35, 1.55, 0.55, 8), _dark_stone(), Vector3(0.0, 0.27, 0.0))
	_add(model.rubble, _cylinder(0.85, 1.0, 1.1, 8), _stone(), Vector3(0.0, 1.0, 0.0), Vector3(0.12, 0.0, 0.08))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234 + team
	for i: int in range(7):
		var chunk := BoxMesh.new()
		chunk.size = Vector3(rng.randf_range(0.3, 0.7), rng.randf_range(0.25, 0.5), rng.randf_range(0.3, 0.7))
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(1.2, 2.2)
		_add(model.rubble, chunk, _stone() if i % 2 == 0 else _dark_stone(),
				Vector3(cos(angle) * dist, 0.15, sin(angle) * dist), Vector3(rng.randf(), rng.randf(), rng.randf()))
	return model


static func build_nexus(team: int) -> StructureModel:
	var model := StructureModel.new()
	model.name = "NexusModel"
	model.spin_speed = 0.5
	model.bob_amplitude = 0.25
	model.intact = Node3D.new()
	model.add_child(model.intact)
	var root: Node3D = model.intact
	_add(root, _cylinder(3.0, 3.4, 0.6, 10), _dark_stone(), Vector3(0.0, 0.3, 0.0))
	_add(root, _cylinder(2.5, 2.7, 0.35, 10), _stone(), Vector3(0.0, 0.75, 0.0))
	_add(root, _cylinder(2.55, 2.55, 0.12, 10), _team_glow(team, 2.0), Vector3(0.0, 0.62, 0.0))
	for i: int in range(5):
		var angle: float = TAU * float(i) / 5.0
		var pillar := BoxMesh.new()
		pillar.size = Vector3(0.45, 2.6, 0.45)
		_add(root, pillar, _stone(), Vector3(cos(angle) * 2.35, 2.1, sin(angle) * 2.35), Vector3(0.0, -angle, 0.0))
		var cap := SphereMesh.new()
		cap.radius = 0.2
		cap.height = 0.4
		_add(root, cap, _team_glow(team, 3.0), Vector3(cos(angle) * 2.35, 3.55, sin(angle) * 2.35))
	model.crystal = Node3D.new()
	model.crystal.position = Vector3(0.0, 3.4, 0.0)
	root.add_child(model.crystal)
	var top := PrismMesh.new()
	top.size = Vector3(1.6, 2.2, 1.6)
	_add(model.crystal, top, _team_glow(team, 3.5), Vector3(0.0, 1.1, 0.0))
	var bottom := PrismMesh.new()
	bottom.size = Vector3(1.6, 1.4, 1.6)
	_add(model.crystal, bottom, _team_glow(team, 3.5), Vector3(0.0, -0.7, 0.0), Vector3(PI, 0.0, 0.0))
	model._crystal_base_y = 3.4
	model._light = OmniLight3D.new()
	model._light.light_color = GameConst.team_color(team)
	model._light.light_energy = 3.0
	model._light.omni_range = 12.0
	model._light.position = Vector3(0.0, 3.5, 0.0)
	root.add_child(model._light)

	model.rubble = Node3D.new()
	model.rubble.visible = false
	model.add_child(model.rubble)
	_add(model.rubble, _cylinder(3.0, 3.4, 0.6, 10), _dark_stone(), Vector3(0.0, 0.3, 0.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 777 + team
	for i: int in range(9):
		var shard := PrismMesh.new()
		shard.size = Vector3(0.5, rng.randf_range(0.6, 1.4), 0.5)
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(0.5, 2.6)
		_add(model.rubble, shard, _material("dead_crystal", GameConst.team_color(team).darkened(0.6), 0.0, 0.4, 0.4),
				Vector3(cos(angle) * dist, 0.7, sin(angle) * dist), Vector3(rng.randf() * 2.0, rng.randf() * 3.0, rng.randf() * 2.0))
	return model


func set_destroyed(destroyed: bool) -> void:
	if intact:
		intact.visible = not destroyed
	if rubble:
		rubble.visible = destroyed


func _process(delta: float) -> void:
	if crystal == null or not intact.visible:
		return
	_time += delta
	crystal.rotation.y += spin_speed * delta
	crystal.position.y = _crystal_base_y + sin(_time * 1.8) * bob_amplitude
	if _light:
		_light.light_energy = (3.0 if spin_speed < 0.7 else 1.6) * (0.85 + 0.15 * sin(_time * 3.0))
