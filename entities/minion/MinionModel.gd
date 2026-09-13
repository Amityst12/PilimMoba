class_name MinionModel
extends Node3D
## Procedurally built minion model (primitive meshes, team colored).

static var _materials: Dictionary = {}

var _bob_time: float = randf() * TAU
var _body: Node3D


static func _material(key: String, color: Color, metallic: float = 0.0, roughness: float = 0.7,
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


static func _mesh(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	instance.rotation = rot
	parent.add_child(instance)
	return instance


static func build(minion_type: int, team: int) -> MinionModel:
	var model := MinionModel.new()
	model.name = "MinionModel"
	var body := Node3D.new()
	body.name = "Body"
	model.add_child(body)
	model._body = body
	var team_color: Color = GameConst.team_color(team)
	var cloth: StandardMaterial3D = _material("cloth_%d" % team, team_color.darkened(0.35), 0.0, 0.8)
	var trim: StandardMaterial3D = _material("trim_%d" % team, team_color.lightened(0.1), 0.2, 0.5, 0.6)
	var metal: StandardMaterial3D = _material("metal", Color(0.62, 0.64, 0.68), 0.8, 0.35)
	if minion_type == Minion.MinionType.CASTER:
		var robe := CylinderMesh.new()
		robe.top_radius = 0.14
		robe.bottom_radius = 0.38
		robe.height = 0.95
		_mesh(body, robe, cloth, Vector3(0.0, 0.48, 0.0))
		var head := SphereMesh.new()
		head.radius = 0.2
		head.height = 0.4
		_mesh(body, head, _material("skin", Color(0.85, 0.72, 0.6)), Vector3(0.0, 1.08, 0.0))
		var hood := CylinderMesh.new()
		hood.top_radius = 0.0
		hood.bottom_radius = 0.24
		hood.height = 0.42
		_mesh(body, hood, cloth, Vector3(0.0, 1.32, 0.02))
		var orb := SphereMesh.new()
		orb.radius = 0.11
		orb.height = 0.22
		_mesh(body, orb, _material("orb_%d" % team, team_color.lightened(0.3), 0.0, 0.2, 4.0), Vector3(0.22, 0.95, -0.3))
		var staff := BoxMesh.new()
		staff.size = Vector3(0.05, 1.1, 0.05)
		_mesh(body, staff, _material("wood", Color(0.4, 0.27, 0.16)), Vector3(0.22, 0.5, -0.3))
	else:
		var torso := CapsuleMesh.new()
		torso.radius = 0.33
		torso.height = 1.0
		_mesh(body, torso, cloth, Vector3(0.0, 0.55, 0.0))
		var chest := BoxMesh.new()
		chest.size = Vector3(0.56, 0.36, 0.42)
		_mesh(body, chest, trim, Vector3(0.0, 0.72, 0.0))
		var helmet := SphereMesh.new()
		helmet.radius = 0.24
		helmet.height = 0.4
		_mesh(body, helmet, metal, Vector3(0.0, 1.12, 0.0))
		var sword := BoxMesh.new()
		sword.size = Vector3(0.06, 0.07, 0.75)
		_mesh(body, sword, metal, Vector3(0.36, 0.6, -0.28))
		var shield := CylinderMesh.new()
		shield.top_radius = 0.24
		shield.bottom_radius = 0.24
		shield.height = 0.05
		_mesh(body, shield, trim, Vector3(-0.38, 0.62, -0.05), Vector3(0.0, 0.0, PI * 0.5))
	return model


func _process(delta: float) -> void:
	if _body == null:
		return
	var entity := get_parent().get_parent() as Entity
	var moving: bool = entity != null and entity.net_velocity.length_squared() > 0.5
	_bob_time += delta * (10.0 if moving else 2.0)
	_body.position.y = absf(sin(_bob_time)) * (0.08 if moving else 0.015)
