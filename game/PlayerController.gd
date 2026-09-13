class_name PlayerController
extends Node
## Local input for the player's champion: click-to-move / attack, attack-move, hold-to-aim
## ability casting with ground indicators, level-ups, recall and camera controls.
## Everything here is client-side; gameplay happens on the server through Game.cmd_* RPCs.

enum Mode { NORMAL, ATTACK_MOVE, AIMING }

const ABILITY_ACTIONS: Array[StringName] = [&"ability_q", &"ability_w", &"ability_e", &"ability_r"]
const MOVE_REPEAT_INTERVAL: float = 0.14

var mode: Mode = Mode.NORMAL
var aiming_slot: int = -1
var hovered: Entity

var _game: Game
var _rig: CameraRig
var _right_held: bool = false
var _move_repeat: float = 0.0
var _indicator_root: Node3D
var _range_ring: MeshInstance3D
var _aim_pivot: Node3D
var _aim_rect: MeshInstance3D
var _aim_circle: MeshInstance3D
var _hover_ring: MeshInstance3D
var _tower_ring: MeshInstance3D
var _self_ring: MeshInstance3D
var _attack_cursor: bool = false


func _ready() -> void:
	_game = get_parent() as Game
	_rig = _game.get_node("CameraRig") as CameraRig
	if DisplayServer.get_name() == "headless":
		set_process(false)
		set_process_unhandled_input(false)
		return
	_build_indicators()


func _build_indicators() -> void:
	_indicator_root = Node3D.new()
	_indicator_root.name = "Indicators"
	_game.get_node("LocalFx").add_child(_indicator_root)
	_range_ring = Fx.ground_decal(_indicator_root, 1.0, Fx.SHAPE_RING, Color(0.55, 0.85, 1.0, 0.55))
	_aim_pivot = Node3D.new()
	_indicator_root.add_child(_aim_pivot)
	_aim_rect = Fx.ground_rect(_aim_pivot, 1.0, 1.0, Color(0.55, 0.85, 1.0, 0.75), Fx.SHAPE_SKILLSHOT)
	_aim_circle = Fx.ground_decal(_indicator_root, 1.0, Fx.SHAPE_DISC, Color(0.55, 0.85, 1.0, 0.8))
	(_aim_circle.material_override as ShaderMaterial).set_shader_parameter("fill_alpha", 0.2)
	_hover_ring = Fx.ground_decal(_indicator_root, 1.0, Fx.SHAPE_RING, GameConst.COLOR_RED)
	(_hover_ring.material_override as ShaderMaterial).set_shader_parameter("edge_width", 0.22)
	_tower_ring = Fx.ground_decal(_indicator_root, Tower.TOWER_RANGE, Fx.SHAPE_RING, Color(1.0, 0.3, 0.3, 0.5))
	(_tower_ring.material_override as ShaderMaterial).set_shader_parameter("edge_width", 0.012)
	_self_ring = Fx.ground_decal(_indicator_root, 1.0, Fx.SHAPE_RING, Color(GameConst.COLOR_SELF, 0.8))
	(_self_ring.material_override as ShaderMaterial).set_shader_parameter("edge_width", 0.16)
	for node: MeshInstance3D in [_range_ring, _aim_rect, _aim_circle, _hover_ring, _tower_ring, _self_ring]:
		node.visible = false


func is_input_blocked() -> bool:
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	return focus_owner is LineEdit or focus_owner is TextEdit


# --- Frame update -------------------------------------------------------------------------------

func _process(delta: float) -> void:
	var champion: Champion = _game.local_champion
	var active: bool = champion != null and not champion.dead and _game.phase == Game.Phase.PLAYING
	hovered = _pick_entity() if _game.phase == Game.Phase.PLAYING else null
	if not active and mode != Mode.NORMAL:
		cancel_aim()
		mode = Mode.NORMAL

	if active and _right_held and mode != Mode.AIMING and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_move_repeat -= delta
		if _move_repeat <= 0.0:
			_move_repeat = MOVE_REPEAT_INTERVAL
			if hovered == null or not hovered.is_targetable_by(champion.team):
				_game.cmd_move.rpc_id(1, _rig.mouse_ground_position())
	elif not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_right_held = false

	_update_indicators(champion)
	_update_cursor(champion)


func _update_indicators(champion: Champion) -> void:
	if _indicator_root == null:
		return
	var has_champion: bool = champion != null and not champion.dead
	_self_ring.visible = has_champion
	if has_champion:
		_self_ring.global_position = Vector3(champion.global_position.x, Fx.DECAL_HEIGHT, champion.global_position.z)
		_self_ring.scale = Vector3.ONE * (champion.radius + 0.35)

	# Hover highlight.
	if hovered and has_champion:
		var enemy: bool = hovered.team != champion.team
		_hover_ring.visible = true
		_hover_ring.global_position = Vector3(hovered.global_position.x, Fx.DECAL_HEIGHT, hovered.global_position.z)
		_hover_ring.scale = Vector3.ONE * (hovered.radius + 0.4)
		(_hover_ring.material_override as ShaderMaterial).set_shader_parameter(
				"color", Color(GameConst.COLOR_RED if enemy else GameConst.COLOR_BLUE, 0.9))
	else:
		_hover_ring.visible = false

	# Enemy tower range warning.
	_tower_ring.visible = false
	if has_champion:
		for structure: Entity in _game.structures:
			if structure is Tower and structure.team != champion.team and not structure.dead:
				var d: float = structure.planar_distance_to_point(champion.global_position)
				if d < Tower.TOWER_RANGE + 6.0:
					_tower_ring.visible = true
					_tower_ring.global_position = Vector3(structure.global_position.x, Fx.DECAL_HEIGHT, structure.global_position.z)
					var targeted: bool = (structure as Tower).target_id == champion.net_id
					var alpha: float = clampf(1.0 - (d - Tower.TOWER_RANGE) / 6.0, 0.25, 1.0)
					(_tower_ring.material_override as ShaderMaterial).set_shader_parameter(
							"color", Color(1.0, 0.15 if targeted else 0.45, 0.2, (0.95 if targeted else 0.55) * alpha))
					break

	# Ability / attack range indicators.
	_range_ring.visible = false
	_aim_rect.visible = false
	_aim_circle.visible = false
	if not has_champion:
		return
	var origin := Vector3(champion.global_position.x, 0.0, champion.global_position.z)
	if mode == Mode.ATTACK_MOVE:
		_show_range_ring(origin, champion.attack_range + champion.radius, Color(1.0, 0.45, 0.35, 0.6))
	elif mode == Mode.AIMING:
		var ability: AbilityData = champion.get_ability(aiming_slot)
		if ability == null:
			return
		var tint: Color = ability.color.lightened(0.35)
		var mouse: Vector3 = _rig.mouse_ground_position()
		match ability.targeting:
			AbilityData.Targeting.DIRECTION:
				_show_range_ring(origin, ability.cast_range, Color(tint, 0.35))
				var length: float = ability.cast_range
				if ability is BeamAbility:
					length = (ability as BeamAbility).beam_length
				_aim_pivot.global_position = origin
				var dir := Vector3(mouse.x - origin.x, 0.0, mouse.z - origin.z)
				if dir.length_squared() > 0.01:
					_aim_pivot.rotation.y = atan2(-dir.x, -dir.z)
				(_aim_rect.mesh as PlaneMesh).size = Vector2(ability.indicator_size, length)
				_aim_rect.position = Vector3(0.0, Fx.DECAL_HEIGHT, -length * 0.5)
				var material := _aim_rect.material_override as ShaderMaterial
				material.set_shader_parameter("color", Color(tint, 0.8))
				material.set_shader_parameter("edge_width", clampf(0.16 / maxf(ability.indicator_size * 0.5, 0.1), 0.02, 0.5))
				material.set_shader_parameter("end_width", clampf(0.16 / length, 0.002, 0.2))
				_aim_rect.visible = true
			AbilityData.Targeting.POINT:
				_show_range_ring(origin, ability.cast_range, Color(tint, 0.35))
				var offset := Vector3(mouse.x - origin.x, 0.0, mouse.z - origin.z)
				if offset.length() > ability.cast_range:
					offset = offset.normalized() * ability.cast_range
				_aim_circle.visible = true
				_aim_circle.global_position = origin + offset + Vector3(0.0, Fx.DECAL_HEIGHT, 0.0)
				_aim_circle.scale = Vector3.ONE * maxf(ability.indicator_size, 0.6)
				(_aim_circle.material_override as ShaderMaterial).set_shader_parameter("color", Color(tint, 0.8))
			AbilityData.Targeting.UNIT:
				_show_range_ring(origin, ability.cast_range + champion.radius, Color(tint, 0.55))


func _show_range_ring(origin: Vector3, ring_radius: float, color: Color) -> void:
	_range_ring.visible = true
	_range_ring.global_position = origin + Vector3(0.0, Fx.DECAL_HEIGHT, 0.0)
	_range_ring.scale = Vector3.ONE * ring_radius
	var material := _range_ring.material_override as ShaderMaterial
	material.set_shader_parameter("color", color)
	material.set_shader_parameter("edge_width", clampf(0.1 / maxf(ring_radius, 0.5), 0.005, 0.2))


func _update_cursor(champion: Champion) -> void:
	var attack: bool = mode == Mode.ATTACK_MOVE or (champion != null and hovered != null and hovered.is_targetable_by(champion.team))
	if attack != _attack_cursor:
		_attack_cursor = attack
		UICursor.set_attack(attack)


# --- Picking ---------------------------------------------------------------------------------------

func _pick_entity() -> Entity:
	var camera: Camera3D = _rig.camera
	if camera == null or get_viewport().gui_get_hovered_control() != null:
		return null
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var best: Entity = null
	var best_score: float = INF
	for entity: Entity in _game.entities.values():
		if entity.dead or (entity is Champion and (entity as Champion).is_local()):
			continue
		var center: Vector3 = entity.global_position + Vector3(0.0, entity.bar_height * 0.4, 0.0)
		if camera.is_position_behind(center):
			continue
		var screen: Vector2 = camera.unproject_position(center)
		var half_width: float = camera.unproject_position(center + camera.global_basis.x * (entity.radius + 0.35)).distance_to(screen)
		var half_height: float = camera.unproject_position(center + Vector3.UP * (entity.bar_height * 0.55)).distance_to(screen)
		var offset: Vector2 = mouse - screen
		var normalized := Vector2(offset.x / maxf(half_width, 8.0), offset.y / maxf(half_height, 10.0))
		var score: float = normalized.length()
		if score <= 1.0 and score < best_score:
			best_score = score
			best = entity
	return best


func _nearest_enemy_to_cursor(team: int, max_distance: float) -> Entity:
	var ground: Vector3 = _rig.mouse_ground_position()
	var best: Entity = null
	var best_distance: float = max_distance
	for entity: Entity in _game.entities.values():
		if entity.is_structure() or not entity.is_targetable_by(team):
			continue
		var d: float = entity.planar_distance_to_point(ground) - entity.radius
		if d < best_distance:
			best_distance = d
			best = entity
	return best


# --- Input ------------------------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _game.phase != Game.Phase.PLAYING or is_input_blocked():
		return
	if event.is_action_pressed("zoom_in"):
		_rig.zoom(-1.0)
		return
	if event.is_action_pressed("zoom_out"):
		_rig.zoom(1.0)
		return
	if event.is_action_pressed("camera_lock"):
		_rig.toggle_lock()
		_game.announcement.emit("Camera %s" % ("locked" if _rig.locked else "unlocked"), Color(0.8, 0.85, 0.9), false)
		return
	var champion: Champion = _game.local_champion
	if champion == null:
		return

	if event.is_action_pressed("ping"):
		_game.cmd_ping.rpc_id(1, GameConst.PingType.ALERT, _rig.mouse_ground_position())
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ping_danger"):
		_game.cmd_ping.rpc_id(1, GameConst.PingType.DANGER, _rig.mouse_ground_position())
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed:
			if mouse_event.alt_pressed or Input.is_key_pressed(KEY_ALT):
				get_viewport().set_input_as_handled()
				var p_type: int = GameConst.PingType.DANGER if mouse_event.button_index == MOUSE_BUTTON_RIGHT else GameConst.PingType.ALERT
				_game.cmd_ping.rpc_id(1, p_type, _rig.mouse_ground_position())
				return
			if (mouse_event.ctrl_pressed or Input.is_key_pressed(KEY_CTRL)) and mouse_event.button_index == MOUSE_BUTTON_LEFT:
				get_viewport().set_input_as_handled()
				_game.cmd_ping.rpc_id(1, GameConst.PingType.ON_MY_WAY, _rig.mouse_ground_position())
				return

		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			get_viewport().set_input_as_handled()
			if mode == Mode.AIMING:
				cancel_aim()
				return
			mode = Mode.NORMAL
			if champion.dead:
				return
			_right_held = true
			_move_repeat = MOVE_REPEAT_INTERVAL
			_issue_smart_click(champion)
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if mode == Mode.AIMING:
				get_viewport().set_input_as_handled()
				_cast_aimed(champion)
			elif mode == Mode.ATTACK_MOVE:
				get_viewport().set_input_as_handled()
				mode = Mode.NORMAL
				if hovered and hovered.is_targetable_by(champion.team):
					_game.cmd_attack.rpc_id(1, hovered.net_id)
				else:
					var point: Vector3 = _rig.mouse_ground_position()
					_game.cmd_attack_move.rpc_id(1, point)
					Fx.click_marker(_game.local_fx, point, Color(1.0, 0.35, 0.3, 0.9))
		return

	if champion.dead:
		return
	if event.is_action_pressed("stop"):
		cancel_aim()
		mode = Mode.NORMAL
		_game.cmd_stop.rpc_id(1)
		return
	if event.is_action_pressed("attack_move"):
		cancel_aim()
		mode = Mode.ATTACK_MOVE
		return
	if event.is_action_pressed("recall"):
		cancel_aim()
		_game.cmd_recall.rpc_id(1)
		return
	for slot: int in range(ABILITY_ACTIONS.size()):
		if event.is_action_pressed(ABILITY_ACTIONS[slot]):
			if Input.is_action_pressed("level_up_modifier"):
				_game.cmd_level_ability.rpc_id(1, slot)
			else:
				begin_aim(slot)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_released(ABILITY_ACTIONS[slot]) and mode == Mode.AIMING and aiming_slot == slot:
			_cast_aimed(champion)
			get_viewport().set_input_as_handled()
			return


func _issue_smart_click(champion: Champion) -> void:
	if hovered and hovered.is_targetable_by(champion.team):
		_game.cmd_attack.rpc_id(1, hovered.net_id)
		Fx.click_marker(_game.local_fx, hovered.global_position, Color(1.0, 0.3, 0.25, 0.95))
	else:
		var point: Vector3 = _rig.mouse_ground_position()
		_game.cmd_move.rpc_id(1, point)
		Fx.click_marker(_game.local_fx, point, Color(0.4, 1.0, 0.5, 0.9))


## Client-side pre-check so the HUD can give instant feedback. The server re-validates everything.
func local_cast_error(champion: Champion, slot: int) -> String:
	var ability: AbilityData = champion.get_ability(slot)
	if ability == null:
		return "invalid"
	if champion.ability_ranks[slot] <= 0:
		return "not_learned"
	if champion.get_cooldown_remaining(slot) > 0.05:
		return "cooldown"
	if champion.mana < ability.get_mana_cost(champion.ability_ranks[slot]):
		return "mana"
	if champion.status_flags & GameConst.FLAG_STUNNED:
		return "stunned"
	return ""


func begin_aim(slot: int) -> void:
	var champion: Champion = _game.local_champion
	if champion == null or champion.dead:
		return
	var error: String = local_cast_error(champion, slot)
	if error != "":
		_game.command_failed.emit(slot, error)
		return
	var ability: AbilityData = champion.get_ability(slot)
	if ability.targeting == AbilityData.Targeting.NONE:
		_game.cmd_cast.rpc_id(1, slot, champion.global_position, -1)
		return
	mode = Mode.AIMING
	aiming_slot = slot


func cancel_aim() -> void:
	if mode == Mode.AIMING:
		mode = Mode.NORMAL
	aiming_slot = -1


func _cast_aimed(champion: Champion) -> void:
	var slot: int = aiming_slot
	var ability: AbilityData = champion.get_ability(slot)
	cancel_aim()
	if ability == null:
		return
	var point: Vector3 = _rig.mouse_ground_position()
	var target_id: int = -1
	if ability.targeting == AbilityData.Targeting.UNIT:
		var target: Entity = hovered
		if target == null or target.is_structure() or not target.is_targetable_by(champion.team):
			target = _nearest_enemy_to_cursor(champion.team, 2.5)
		if target == null:
			_game.command_failed.emit(slot, "no_target")
			return
		target_id = target.net_id
		point = target.global_position
	_game.cmd_cast.rpc_id(1, slot, point, target_id)
