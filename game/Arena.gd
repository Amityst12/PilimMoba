class_name Arena
extends Node3D
## The battlefield. The layout is defined as data in `_define_layout()` and used to build
## collision, the navigation mesh (baked at runtime), decorations and the minimap.
## The map is point-symmetric around the origin so both teams play on equal terms.

signal navigation_ready

const HALF_X: float = 66.0
const HALF_Z: float = 34.0
const LANE_HALF_WIDTH: float = 7.5
const FOUNTAIN_X: float = 58.5
const NEXUS_X: float = 50.0
const INNER_TOWER: Vector2 = Vector2(-38.0, 2.5)
const OUTER_TOWER: Vector2 = Vector2(-22.0, -2.5)
const RIDGE_Z: float = 12.0
const RIDGE_THICKNESS: float = 3.2
const RIVER_HALF_WIDTH: float = 4.2

## Build decorations (trees, rocks, grass). Disabled automatically on headless servers.
@export var build_decorations: bool = true

## Obstacles: {"type": "box", "center": Vector2, "size": Vector2} or {"type": "circle", "center": Vector2, "radius": float}
var obstacles: Array[Dictionary] = []
## Visual-only tall grass patches: {"center": Vector2, "size": Vector2}
var brushes: Array[Dictionary] = []
var nav_ready: bool = false

@onready var nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var obstacles_root: Node3D = $Obstacles
@onready var decorations_root: Node3D = $Decorations
@onready var ground: MeshInstance3D = $Ground


func _ready() -> void:
	_define_layout()
	_build_collision()
	_setup_ground()
	if build_decorations and DisplayServer.get_name() != "headless":
		_build_decorations()
		_build_fountains()
	bake_navigation()


# --- Layout -----------------------------------------------------------------------------

func _define_layout() -> void:
	obstacles.clear()
	brushes.clear()
	# Ridges separating the lane from the jungle, with entrances near the outer towers and the river.
	var ridge_segments: Array[Vector2] = [
		Vector2(-55.0, 23.0),  # base side wall (center x, length)
		Vector2(-37.5, 13.0),
		Vector2(-15.0, 18.0),
	]
	for seg: Vector2 in ridge_segments:
		_add_mirrored_box(Vector2(seg.x, RIDGE_Z), Vector2(seg.y, RIDGE_THICKNESS))
		_add_mirrored_box(Vector2(-seg.x, RIDGE_Z), Vector2(seg.y, RIDGE_THICKNESS))
	# Jungle rock formations (top half; mirrored to the bottom half).
	_add_mirrored_circle(Vector2(-18.0, 22.5), 3.4)
	_add_mirrored_circle(Vector2(8.5, 20.5), 2.6)
	_add_mirrored_circle(Vector2(31.0, 25.5), 3.2)
	_add_mirrored_circle(Vector2(-33.0, 27.5), 2.8)
	_add_mirrored_box(Vector2(-47.0, 25.0), Vector2(7.0, 6.0))
	_add_mirrored_box(Vector2(47.0, 25.0), Vector2(7.0, 6.0))
	_add_mirrored_circle(Vector2(-5.0, 29.0), 2.2)
	_add_mirrored_circle(Vector2(20.0, 30.5), 2.0)
	# Tall grass (visual) along the lane edges and inside the jungle.
	for b: Vector2 in [Vector2(-9.0, 8.8), Vector2(28.0, 8.8), Vector2(-24.0, 19.0), Vector2(14.0, 26.0)]:
		brushes.append({"center": b, "size": Vector2(5.5, 2.4)})
		brushes.append({"center": -b, "size": Vector2(5.5, 2.4)})


func is_in_brush(pos: Vector3) -> bool:
	return get_brush_index(pos) != -1


func get_brush_index(pos: Vector3) -> int:
	var p := Vector2(pos.x, pos.z)
	for i: int in range(brushes.size()):
		var b: Dictionary = brushes[i]
		var center: Vector2 = b["center"]
		var size: Vector2 = b["size"]
		var half: Vector2 = size * 0.5
		if absf(p.x - center.x) <= half.x and absf(p.y - center.y) <= half.y:
			return i
	return -1


func _add_mirrored_box(center: Vector2, size: Vector2) -> void:
	obstacles.append({"type": "box", "center": center, "size": size})
	obstacles.append({"type": "box", "center": -center, "size": size})


func _add_mirrored_circle(center: Vector2, circle_radius: float) -> void:
	obstacles.append({"type": "circle", "center": center, "radius": circle_radius})
	obstacles.append({"type": "circle", "center": -center, "radius": circle_radius})


static func team_sign(team: int) -> float:
	return -1.0 if team == GameConst.TEAM_BLUE else 1.0


static func fountain_position(team: int) -> Vector3:
	return Vector3(FOUNTAIN_X * team_sign(team), 0.0, 0.0)


static func nexus_position(team: int) -> Vector3:
	return Vector3(NEXUS_X * team_sign(team), 0.0, 0.0)


static func minion_spawn_position(team: int) -> Vector3:
	return Vector3((NEXUS_X - 4.5) * team_sign(team), 0.0, 0.0)


## Positions of every structure: [{kind: "tower"|"nexus", team, tier, pos}]
static func structure_layout() -> Array[Dictionary]:
	var layout: Array[Dictionary] = []
	for team: int in [GameConst.TEAM_BLUE, GameConst.TEAM_RED]:
		var mirror: float = 1.0 if team == GameConst.TEAM_BLUE else -1.0
		layout.append({"kind": "tower", "team": team, "tier": 1, "pos": Vector3(OUTER_TOWER.x * mirror, 0.0, OUTER_TOWER.y * mirror)})
		layout.append({"kind": "tower", "team": team, "tier": 2, "pos": Vector3(INNER_TOWER.x * mirror, 0.0, INNER_TOWER.y * mirror)})
		layout.append({"kind": "nexus", "team": team, "tier": 3, "pos": nexus_position(team)})
	return layout


## Lane path for minions of `team`, from their base to the enemy nexus.
static func lane_waypoints(team: int) -> PackedVector3Array:
	var direction: float = 1.0 if team == GameConst.TEAM_BLUE else -1.0
	var points := PackedVector3Array()
	for x: float in [-44.0, -30.0, -12.0, 0.0, 12.0, 30.0, 44.0, NEXUS_X]:
		points.append(Vector3(x * direction, 0.0, 0.0))
	return points


static func clamp_to_bounds(point: Vector3) -> Vector3:
	return Vector3(clampf(point.x, -HALF_X + 0.5, HALF_X - 0.5), 0.0, clampf(point.z, -HALF_Z + 0.5, HALF_Z - 0.5))


# --- Collision ------------------------------------------------------------------------------

func _build_collision() -> void:
	for obstacle: Dictionary in obstacles:
		var body := StaticBody3D.new()
		body.collision_layer = GameConst.LAYER_WORLD
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var center: Vector2 = obstacle["center"]
		if obstacle["type"] == "box":
			var box := BoxShape3D.new()
			var size: Vector2 = obstacle["size"]
			box.size = Vector3(size.x, 4.0, size.y)
			shape.shape = box
		else:
			var cylinder := CylinderShape3D.new()
			cylinder.radius = float(obstacle["radius"])
			cylinder.height = 4.0
			shape.shape = cylinder
		body.add_child(shape)
		body.position = Vector3(center.x, 2.0, center.y)
		obstacles_root.add_child(body)
	# Map boundary walls.
	var walls: Array = [
		[Vector3(0.0, 2.0, -HALF_Z - 1.0), Vector3(HALF_X * 2.0 + 4.0, 4.0, 2.0)],
		[Vector3(0.0, 2.0, HALF_Z + 1.0), Vector3(HALF_X * 2.0 + 4.0, 4.0, 2.0)],
		[Vector3(-HALF_X - 1.0, 2.0, 0.0), Vector3(2.0, 4.0, HALF_Z * 2.0 + 4.0)],
		[Vector3(HALF_X + 1.0, 2.0, 0.0), Vector3(2.0, 4.0, HALF_Z * 2.0 + 4.0)],
	]
	for wall: Array in walls:
		var body := StaticBody3D.new()
		body.collision_layer = GameConst.LAYER_WORLD
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = wall[1]
		shape.shape = box
		body.add_child(shape)
		body.position = wall[0]
		obstacles_root.add_child(body)


# --- Navigation ------------------------------------------------------------------------------

func bake_navigation() -> void:
	var nav_mesh := NavigationMesh.new()
	nav_mesh.agent_radius = 0.6
	nav_mesh.agent_height = 2.0
	nav_mesh.agent_max_climb = 0.4
	nav_mesh.cell_size = 0.25
	nav_mesh.cell_height = 0.25
	nav_mesh.edge_max_error = 1.0
	nav_mesh.region_min_size = 2.0
	var source := NavigationMeshSourceGeometryData3D.new()
	var a := Vector3(-HALF_X, 0.0, -HALF_Z)
	var b := Vector3(HALF_X, 0.0, -HALF_Z)
	var c := Vector3(HALF_X, 0.0, HALF_Z)
	var d := Vector3(-HALF_X, 0.0, HALF_Z)
	# Both windings so the ground is walkable regardless of face orientation.
	source.add_faces(PackedVector3Array([a, b, c, a, c, d, a, c, b, a, d, c]), Transform3D.IDENTITY)
	for obstacle: Dictionary in obstacles:
		source.add_projected_obstruction(obstacle_outline(obstacle), -1.0, 5.0, false)
	for structure: Dictionary in structure_layout():
		var pos: Vector3 = structure["pos"]
		var r: float = 1.25 if structure["kind"] == "tower" else 2.4
		source.add_projected_obstruction(_circle_outline(Vector2(pos.x, pos.z), r, 12), -1.0, 5.0, false)
	NavigationServer3D.bake_from_source_geometry_data(nav_mesh, source)
	nav_region.navigation_mesh = nav_mesh
	# The navigation map synchronizes on the next physics frames.
	await get_tree().physics_frame
	await get_tree().physics_frame
	nav_ready = true
	navigation_ready.emit()


func obstacle_outline(obstacle: Dictionary) -> PackedVector3Array:
	var center: Vector2 = obstacle["center"]
	if obstacle["type"] == "box":
		var half: Vector2 = obstacle["size"] * 0.5
		return PackedVector3Array([
			Vector3(center.x - half.x, 0.0, center.y - half.y),
			Vector3(center.x + half.x, 0.0, center.y - half.y),
			Vector3(center.x + half.x, 0.0, center.y + half.y),
			Vector3(center.x - half.x, 0.0, center.y + half.y),
		])
	return _circle_outline(center, float(obstacle["radius"]), 14)


static func _circle_outline(center: Vector2, circle_radius: float, segments: int) -> PackedVector3Array:
	var points := PackedVector3Array()
	for i: int in range(segments):
		var angle: float = TAU * float(i) / float(segments)
		points.append(Vector3(center.x + cos(angle) * circle_radius, 0.0, center.y + sin(angle) * circle_radius))
	return points


func navigation_polygon_count() -> int:
	return nav_region.navigation_mesh.get_polygon_count() if nav_region.navigation_mesh else 0


# --- Visuals ------------------------------------------------------------------------------------

func _setup_ground() -> void:
	var material := ground.material_override as ShaderMaterial
	if material == null:
		return
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.02
	noise.fractal_octaves = 4
	var texture := NoiseTexture2D.new()
	texture.width = 512
	texture.height = 512
	texture.seamless = true
	texture.generate_mipmaps = true
	texture.noise = noise
	material.set_shader_parameter("noise_tex", texture)
	material.set_shader_parameter("map_half", Vector2(HALF_X, HALF_Z))
	material.set_shader_parameter("lane_half_width", LANE_HALF_WIDTH)
	material.set_shader_parameter("river_half_width", RIVER_HALF_WIDTH)
	material.set_shader_parameter("blue_base", Vector2(-FOUNTAIN_X + 1.5, 0.0))
	material.set_shader_parameter("red_base", Vector2(FOUNTAIN_X - 1.5, 0.0))


func _build_decorations() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	var trunk_transforms: Array[Transform3D] = []
	var crown_transforms: Array[Transform3D] = []
	var rock_transforms: Array[Transform3D] = []

	# Rock ridges and formations with trees on top.
	for obstacle: Dictionary in obstacles:
		var center: Vector2 = obstacle["center"]
		if obstacle["type"] == "box":
			var size: Vector2 = obstacle["size"]
			var count: int = int(size.x * size.y / 3.5) + 2
			for i: int in range(count):
				var p := Vector2(center.x + rng.randf_range(-0.5, 0.5) * size.x, center.y + rng.randf_range(-0.5, 0.5) * size.y)
				rock_transforms.append(_rock_transform(rng, p, rng.randf_range(1.0, 1.9)))
			var tree_count: int = int(size.x * size.y / 9.0) + 1
			for i: int in range(tree_count):
				var p := Vector2(center.x + rng.randf_range(-0.42, 0.42) * size.x, center.y + rng.randf_range(-0.35, 0.35) * size.y)
				_add_tree(rng, p, trunk_transforms, crown_transforms, rng.randf_range(0.9, 1.4))
		else:
			var r: float = float(obstacle["radius"])
			for i: int in range(int(r * 3.0) + 2):
				var angle: float = rng.randf() * TAU
				var dist: float = sqrt(rng.randf()) * r * 0.8
				rock_transforms.append(_rock_transform(rng, center + Vector2(cos(angle), sin(angle)) * dist, rng.randf_range(0.9, 1.7) * r / 2.5 + 0.4))
			_add_tree(rng, center + Vector2(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.3, 0.3)) * r, trunk_transforms, crown_transforms, 1.2)

	# Dense forest outside the playable area.
	for i: int in range(420):
		var p := Vector2(rng.randf_range(-HALF_X - 14.0, HALF_X + 14.0), rng.randf_range(-HALF_Z - 12.0, HALF_Z + 12.0))
		if absf(p.x) < HALF_X + 1.5 and absf(p.y) < HALF_Z + 1.5:
			continue
		_add_tree(rng, p, trunk_transforms, crown_transforms, rng.randf_range(1.1, 1.8))
	for i: int in range(90):
		var p := Vector2(rng.randf_range(-HALF_X - 6.0, HALF_X + 6.0), rng.randf_range(-HALF_Z - 5.0, HALF_Z + 5.0))
		if absf(p.x) < HALF_X + 0.5 and absf(p.y) < HALF_Z + 0.5:
			continue
		rock_transforms.append(_rock_transform(rng, p, rng.randf_range(1.2, 2.6)))

	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.16
	trunk_mesh.bottom_radius = 0.28
	trunk_mesh.height = 1.6
	trunk_mesh.radial_segments = 6
	trunk_mesh.material = _simple_material(Color(0.33, 0.23, 0.15), 0.9)
	var crown_mesh := CylinderMesh.new()
	crown_mesh.top_radius = 0.0
	crown_mesh.bottom_radius = 1.3
	crown_mesh.height = 3.2
	crown_mesh.radial_segments = 7
	crown_mesh.material = _simple_material(Color(0.16, 0.34, 0.17), 0.85)
	var rock_mesh := SphereMesh.new()
	rock_mesh.radius = 0.6
	rock_mesh.height = 1.0
	rock_mesh.radial_segments = 7
	rock_mesh.rings = 4
	rock_mesh.material = _simple_material(Color(0.4, 0.4, 0.42), 0.95)
	_add_multimesh(trunk_mesh, trunk_transforms, true)
	_add_multimesh(crown_mesh, crown_transforms, true)
	_add_multimesh(rock_mesh, rock_transforms, true)
	_build_grass(rng)


func _rock_transform(rng: RandomNumberGenerator, p: Vector2, size: float) -> Transform3D:
	var basis := Basis.from_euler(Vector3(rng.randf_range(-0.3, 0.3), rng.randf() * TAU, rng.randf_range(-0.3, 0.3)))
	basis = basis.scaled(Vector3(size * rng.randf_range(1.0, 1.6), size * rng.randf_range(0.7, 1.3), size * rng.randf_range(1.0, 1.6)))
	return Transform3D(basis, Vector3(p.x, size * 0.25, p.y))


func _add_tree(rng: RandomNumberGenerator, p: Vector2, trunks: Array[Transform3D], crowns: Array[Transform3D], size: float) -> void:
	var yaw: float = rng.randf() * TAU
	var trunk_basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * size)
	trunks.append(Transform3D(trunk_basis, Vector3(p.x, 0.8 * size, p.y)))
	var crown_basis := Basis(Vector3.UP, yaw).scaled(Vector3(size, size * rng.randf_range(0.9, 1.25), size))
	crowns.append(Transform3D(crown_basis, Vector3(p.x, (1.6 + 1.5) * size, p.y)))


func _add_multimesh(mesh: Mesh, transforms: Array[Transform3D], shadows: bool) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for i: int in range(transforms.size()):
		multimesh.set_instance_transform(i, transforms[i])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	decorations_root.add_child(instance)


func _build_grass(rng: RandomNumberGenerator) -> void:
	var blade_mesh := PrismMesh.new()
	blade_mesh.size = Vector3(0.12, 0.55, 0.05)
	var grass_material := _simple_material(Color(0.28, 0.5, 0.2), 0.9)
	grass_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	blade_mesh.material = grass_material
	var tall_mesh := PrismMesh.new()
	tall_mesh.size = Vector3(0.22, 1.3, 0.08)
	var tall_material := _simple_material(Color(0.2, 0.42, 0.16), 0.9)
	tall_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	tall_mesh.material = tall_material
	var blades: Array[Transform3D] = []
	var tall: Array[Transform3D] = []
	for i: int in range(2600):
		var p := Vector2(rng.randf_range(-HALF_X, HALF_X), rng.randf_range(-HALF_Z, HALF_Z))
		if absf(p.y) < LANE_HALF_WIDTH + 0.5 or absf(p.x + sin(p.y * 0.12) * 1.6) < RIVER_HALF_WIDTH + 0.5:
			continue
		if Vector2(p.x - fountain_position(1).x, p.y).length() < 14.0 or Vector2(p.x - fountain_position(2).x, p.y).length() < 14.0:
			continue
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.7, 1.4))
		blades.append(Transform3D(basis, Vector3(p.x, 0.25, p.y)))
	for brush: Dictionary in brushes:
		var center: Vector2 = brush["center"]
		var size: Vector2 = brush["size"]
		for i: int in range(int(size.x * size.y * 5.0)):
			var p := center + Vector2(rng.randf_range(-0.5, 0.5) * size.x, rng.randf_range(-0.5, 0.5) * size.y)
			var basis := Basis.from_euler(Vector3(rng.randf_range(-0.25, 0.25), rng.randf() * TAU, rng.randf_range(-0.25, 0.25)))
			tall.append(Transform3D(basis.scaled(Vector3.ONE * rng.randf_range(0.8, 1.3)), Vector3(p.x, 0.55, p.y)))
	_add_multimesh(blade_mesh, blades, false)
	_add_multimesh(tall_mesh, tall, true)


func _build_fountains() -> void:
	for team: int in [GameConst.TEAM_BLUE, GameConst.TEAM_RED]:
		var root := Node3D.new()
		root.name = "Fountain%s" % GameConst.team_name(team)
		decorations_root.add_child(root)
		root.position = fountain_position(team)
		var color: Color = GameConst.team_color(team)
		var platform := MeshInstance3D.new()
		var platform_mesh := CylinderMesh.new()
		platform_mesh.top_radius = 3.2
		platform_mesh.bottom_radius = 3.6
		platform_mesh.height = 0.3
		platform_mesh.radial_segments = 24
		platform_mesh.material = _simple_material(Color(0.36, 0.37, 0.42), 0.6)
		platform.mesh = platform_mesh
		platform.position.y = 0.15
		root.add_child(platform)
		var ring := Fx.ground_decal(root, GameConst.FOUNTAIN_RADIUS, Fx.SHAPE_RING, Color(color, 0.55))
		(ring.material_override as ShaderMaterial).set_shader_parameter("pulse_speed", 2.0)
		(ring.material_override as ShaderMaterial).set_shader_parameter("edge_width", 0.03)
		var inner := Fx.ground_decal(root, 3.0, Fx.SHAPE_DISC, Color(color, 0.5))
		inner.position.y = 0.32
		(inner.material_override as ShaderMaterial).set_shader_parameter("fill_alpha", 0.35)
		var light := OmniLight3D.new()
		light.light_color = color
		light.light_energy = 2.5
		light.omni_range = 10.0
		light.position = Vector3(0.0, 2.5, 0.0)
		root.add_child(light)
		var particles := CPUParticles3D.new()
		particles.amount = 40
		particles.lifetime = 2.2
		particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
		particles.emission_ring_radius = 3.0
		particles.emission_ring_inner_radius = 2.4
		particles.emission_ring_height = 0.1
		particles.emission_ring_axis = Vector3.UP
		particles.direction = Vector3.UP
		particles.spread = 8.0
		particles.gravity = Vector3(0.0, 1.2, 0.0)
		particles.initial_velocity_min = 0.6
		particles.initial_velocity_max = 1.4
		var spark := SphereMesh.new()
		spark.radius = 0.06
		spark.height = 0.12
		spark.material = Fx.glow_material(Color(color.r * 1.5, color.g * 1.5, color.b * 1.5, 0.9))
		particles.mesh = spark
		particles.position.y = 0.3
		root.add_child(particles)


func _simple_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
