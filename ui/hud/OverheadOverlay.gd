extends Control
## Renders floating screen-space overhead health bars, delayed damage chunks,
## shield segments, mana bars, level pips, and status effects above all alive units.

var _game: Game
var _delayed_health: Dictionary = {}  # net_id -> float (lagging health value)
var _delay_timers: Dictionary = {}   # net_id -> float (hold time before draining)
var _popups: Array[Dictionary] = []  # {world_pos, text, color, elapsed, duration, offset_x}

const MINION_SIZE: Vector2 = Vector2(42.0, 5.0)
const STRUCTURE_SIZE: Vector2 = Vector2(74.0, 8.0)
const CHAMPION_SIZE: Vector2 = Vector2(84.0, 9.0)
const MONSTER_SIZE: Vector2 = Vector2(60.0, 7.0)


func spawn_combat_text(world_pos: Vector3, text: String, color: Color) -> void:
	_popups.append({
		"world_pos": world_pos,
		"text": text,
		"color": color,
		"elapsed": 0.0,
		"duration": 0.85,
		"offset_x": randf_range(-14.0, 14.0),
	})


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if _game == null:
		_game = Game.current
	if _game == null or not _game.is_playing() or _game.camera_rig == null:
		return

	# Update popups
	if not _popups.is_empty():
		var active_popups: Array[Dictionary] = []
		for p: Dictionary in _popups:
			p["elapsed"] += delta
			if p["elapsed"] < p["duration"]:
				active_popups.append(p)
		_popups = active_popups

	# Update lagging damage chunk bars
	for id: int in _delay_timers.keys():
		var t: float = _delay_timers[id] - delta
		if t <= 0.0:
			_delay_timers.erase(id)
		else:
			_delay_timers[id] = t

	for id: int in _delayed_health.keys():
		var entity: Entity = _game.get_entity(id)
		if entity == null or entity.dead:
			_delayed_health.erase(id)
			_delay_timers.erase(id)
			continue
		if not _delay_timers.has(id):
			var current_hp: float = entity.health
			var delayed: float = _delayed_health[id]
			if delayed > current_hp:
				_delayed_health[id] = move_toward(delayed, current_hp, delta * entity.max_health * 1.5)
			else:
				_delayed_health[id] = current_hp

	queue_redraw()


func _draw() -> void:
	if _game == null or not _game.is_playing() or _game.camera_rig == null:
		return
	var camera: Camera3D = _game.camera_rig.camera
	if camera == null:
		return

	var local_team: int = _game.local_team()
	var vp_size: Vector2 = get_viewport_rect().size

	for entity: Entity in _game.entities.values():
		if entity == null or entity.dead or not entity.is_inside_tree():
			continue

		# Bush stealth check: if enemy and concealed, do not draw overhead bar!
		var is_concealed: bool = false
		if entity is Champion:
			is_concealed = (entity as Champion).is_concealed
		if is_concealed and entity.team != local_team and entity.team != GameConst.TEAM_NONE:
			continue

		var head_pos: Vector3 = entity.global_position + Vector3(0.0, entity.bar_height, 0.0)
		if camera.is_position_behind(head_pos):
			continue

		var screen_pos: Vector2 = camera.unproject_position(head_pos)
		# Offscreen check
		if screen_pos.x < -100 or screen_pos.x > vp_size.x + 100 or screen_pos.y < -100 or screen_pos.y > vp_size.y + 100:
			continue

		_draw_entity_bar(entity, screen_pos, local_team)

	# Draw floating combat text popups
	if not _popups.is_empty():
		var font_bold: Font = UITheme.font(true)
		for p: Dictionary in _popups:
			var w_pos: Vector3 = p["world_pos"]
			if camera.is_position_behind(w_pos):
				continue
			var base_screen: Vector2 = camera.unproject_position(w_pos)
			var progress: float = p["elapsed"] / p["duration"]
			var rise: float = progress * 42.0
			var fade: float = 1.0 - ease(progress, 2.0)
			var draw_pos := Vector2(base_screen.x + p["offset_x"], base_screen.y - rise)
			var col: Color = p["color"]
			col.a *= fade
			var outline_col := Color(0.0, 0.0, 0.0, fade * 0.9)
			draw_string_outline(font_bold, draw_pos, p["text"], HORIZONTAL_ALIGNMENT_CENTER, -1, 14, 3, outline_col)
			draw_string(font_bold, draw_pos, p["text"], HORIZONTAL_ALIGNMENT_CENTER, -1, 14, col)


func _draw_entity_bar(entity: Entity, center: Vector2, local_team: int) -> void:
	var is_champ: bool = entity is Champion
	var is_structure: bool = entity.is_structure()
	var is_monster: bool = entity.get_kind() == Entity.Kind.MINION and entity.team == GameConst.TEAM_NONE

	var bar_size: Vector2 = MINION_SIZE
	if is_champ:
		bar_size = CHAMPION_SIZE
	elif is_structure:
		bar_size = STRUCTURE_SIZE
	elif is_monster:
		bar_size = MONSTER_SIZE

	var top_left := center - Vector2(bar_size.x * 0.5, bar_size.y * 0.5)

	# Health fraction and delayed health
	var hp_frac: float = clampf(entity.health_fraction(), 0.0, 1.0)
	var max_hp: float = maxf(entity.max_health, 1.0)

	if not _delayed_health.has(entity.net_id):
		_delayed_health[entity.net_id] = entity.health
	elif entity.health < _delayed_health[entity.net_id] and not _delay_timers.has(entity.net_id):
		_delay_timers[entity.net_id] = 0.35

	var delayed_hp: float = _delayed_health.get(entity.net_id, entity.health)
	var delay_frac: float = clampf(delayed_hp / max_hp, 0.0, 1.0)

	# Colors
	var bar_color: Color
	if entity is Champion and (entity as Champion).is_local():
		bar_color = Color(0.2, 0.85, 0.35)  # Vibrant green for local player
	elif entity.team == local_team:
		bar_color = Color(0.25, 0.6, 1.0)   # Friendly blue
	elif entity.team == GameConst.TEAM_NONE:
		bar_color = Color(0.95, 0.65, 0.2)  # Neutral monster gold
	else:
		bar_color = Color(0.95, 0.25, 0.25)  # Hostile enemy red

	# 1. Background (dark border)
	var border_rect := Rect2(top_left - Vector2(1, 1), bar_size + Vector2(2, 2))
	draw_rect(border_rect, Color(0.02, 0.03, 0.05, 0.9), true)

	# 2. Delayed damage white/yellow chunk
	if delay_frac > hp_frac:
		var delay_width: float = bar_size.x * delay_frac
		draw_rect(Rect2(top_left, Vector2(delay_width, bar_size.y)), Color(1.0, 0.9, 0.4, 0.9), true)

	# 3. Main health fill
	var fill_width: float = bar_size.x * hp_frac
	if fill_width > 0.0:
		draw_rect(Rect2(top_left, Vector2(fill_width, bar_size.y)), bar_color, true)

	# 4. Shield overlay
	if entity.shield > 0.0:
		var shield_frac: float = clampf(entity.shield / max_hp, 0.0, 1.0 - hp_frac)
		var shield_x: float = top_left.x + fill_width
		var shield_width: float = bar_size.x * shield_frac
		draw_rect(Rect2(Vector2(shield_x, top_left.y), Vector2(shield_width, bar_size.y)), Color(0.85, 0.95, 1.0, 0.85), true)

	# 5. Segment pips for champions (notches every 250 HP)
	if is_champ and max_hp >= 250.0:
		var num_pips: int = int(max_hp / 250.0)
		for p: int in range(1, num_pips):
			var pip_x: float = top_left.x + (float(p * 250) / max_hp) * bar_size.x
			if pip_x < top_left.x + bar_size.x - 1.0:
				draw_line(Vector2(pip_x, top_left.y), Vector2(pip_x, top_left.y + bar_size.y), Color(0.0, 0.0, 0.0, 0.5), 1.0)

	# 6. Mana bar underneath for Champions
	if is_champ:
		var champ := entity as Champion
		var mana_frac: float = clampf(champ.mana / maxf(champ.max_mana, 1.0), 0.0, 1.0)
		var mana_y: float = top_left.y + bar_size.y + 1.0
		draw_rect(Rect2(Vector2(top_left.x - 1, mana_y), Vector2(bar_size.x + 2, 3)), Color(0.02, 0.03, 0.05, 0.9), true)
		draw_rect(Rect2(Vector2(top_left.x, mana_y + 0.5), Vector2(bar_size.x * mana_frac, 2)), Color(0.2, 0.6, 1.0), true)

		# Level Box on Left
		var lvl_box_size := Vector2(16.0, bar_size.y + 4.0)
		var lvl_box_pos := Vector2(top_left.x - lvl_box_size.x - 2.0, top_left.y - 1.0)
		draw_rect(Rect2(lvl_box_pos, lvl_box_size), Color(0.05, 0.07, 0.1, 0.95), true)
		draw_rect(Rect2(lvl_box_pos, lvl_box_size), Color(UITheme.ACCENT, 0.8), false, 1.0)
		draw_string(UITheme.font(true), lvl_box_pos + Vector2(3, 10), str(champ.level), HORIZONTAL_ALIGNMENT_CENTER, -1, 10, UITheme.TEXT)

		# Name Label
		var name_str: String = champ.player_name
		var font: Font = UITheme.font(false)
		draw_string(font, Vector2(top_left.x, top_left.y - 4.0), name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UITheme.TEXT)

	# 7. Status Badges above bar
	if entity.status_flags != 0:
		var status_text := ""
		var status_color := Color.WHITE
		if entity.status_flags & GameConst.FLAG_STUNNED:
			status_text = "STUNNED"
			status_color = Color(1.0, 0.85, 0.2)
		elif entity.status_flags & GameConst.FLAG_ROOTED:
			status_text = "ROOTED"
			status_color = Color(1.0, 0.5, 0.2)
		elif entity.status_flags & GameConst.FLAG_SILENCED:
			status_text = "SILENCED"
			status_color = Color(0.8, 0.4, 1.0)

		if not status_text.is_empty():
			var font: Font = UITheme.font(true)
			draw_string(font, Vector2(center.x - 22, top_left.y - (18.0 if is_champ else 6.0)), status_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, status_color)
