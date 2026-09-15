class_name HUD
extends CanvasLayer
## In-game MOBA HUD: health/mana bars, abilities, items, shop, minimap,
## kill feed, announcements, scoreboard and victory/defeat screens.

const HealthRelic = preload("res://entities/relic/HealthRelic.gd")
const OverheadOverlay = preload("res://ui/hud/OverheadOverlay.gd")

var _game: Game
var _champion: Champion

# --- Top Bar ---
var _clock_label: Label
var _blue_score_label: Label
var _red_score_label: Label
var _kda_label: Label
var _cs_label: Label

# --- Bottom Bar ---
var _portrait_rect: TextureRect
var _level_badge: Label
var _xp_bar: ProgressBar
var _hp_bar: ProgressBar
var _hp_label: Label
var _mana_bar: ProgressBar
var _mana_label: Label
var _ad_label: Label
var _ap_label: Label
var _armor_label: Label
var _mr_label: Label
var _as_label: Label
var _ms_label: Label

# Ability slots
var _passive_card: Control
var _passive_icon: TextureRect
var _passive_stacks_label: Label
var _ability_cards: Array[Dictionary] = []  # [{root, icon, key, cost, cd_overlay, cd_label, level_btn, pips}]

# Inventory & Shop
var _item_slots: Array[TextureRect] = []
var _gold_label: Label
var _shop_button: Button
var _recall_button: Button

# Recall Channel UI
var _recall_container: Control
var _recall_progress: ProgressBar
var _recall_timer_label: Label

# Minimap
var _minimap_view: Control
var _active_pings: Array[Dictionary] = []
var _minimap_dragging: bool = false
var _minimap_drag_start_time: float = 0.0
const MINIMAP_W: float = 190.0
const MINIMAP_H: float = 110.0

# Modals & Overlays
var _shop_modal: Control
var _shop_item_list: VBoxContainer
var _shop_selected_item: String = ""
var _shop_details_label: Label
var _shop_buy_btn: Button
var _shop_inv_row: HFlowContainer
var _scoreboard_modal: Control
var _scoreboard_blue: VBoxContainer
var _scoreboard_red: VBoxContainer
var _announcement_box: Control
var _announcement_label: Label
var _announcement_tween: Tween
var _kill_feed_box: VBoxContainer
var _game_over_modal: Control
var _game_over_title: Label
var _game_over_details: Label
var _settings_modal: Control


func _ready() -> void:
	_game = Game.current
	if _game:
		_game.local_champion_changed.connect(_on_local_champion_changed)
		_game.announcement.connect(_on_announcement)
		_game.kill_feed.connect(_on_kill_feed)
		_game.phase_changed.connect(_on_phase_changed)
		_game.command_failed.connect(_on_command_failed)
		_game.ping_received.connect(_on_ping_received)
	_build_ui()


func _on_local_champion_changed(champ: Champion) -> void:
	_champion = champ
	_update_kit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_P or event.keycode == KEY_B and Input.is_key_pressed(KEY_CTRL):
			_toggle_shop()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_TAB:
			_scoreboard_modal.visible = not _scoreboard_modal.visible
			if _scoreboard_modal.visible:
				_refresh_scoreboard()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			if _shop_modal.visible:
				_shop_modal.visible = false
				get_viewport().set_input_as_handled()
			elif _scoreboard_modal.visible:
				_scoreboard_modal.visible = false
				get_viewport().set_input_as_handled()
			elif is_instance_valid(_settings_modal):
				_settings_modal.queue_free()
				get_viewport().set_input_as_handled()
			else:
				_open_settings()
				get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_update_clock_and_score()
	if _champion != null and is_instance_valid(_champion):
		_update_bars()
		_update_abilities()
		_update_inventory()
		_update_recall()
	_update_pings(delta)
	if _minimap_view:
		_minimap_view.queue_redraw()
	if _minimap_dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_minimap_dragging = false
		var hold_duration: float = (Time.get_ticks_msec() / 1000.0) - _minimap_drag_start_time
		if _game and _game.camera_rig:
			_game.camera_rig.end_minimap_peek(hold_duration)


func _update_pings(delta: float) -> void:
	var i: int = _active_pings.size() - 1
	while i >= 0:
		_active_pings[i]["time_left"] -= delta
		if _active_pings[i]["time_left"] <= 0.0:
			_active_pings.remove_at(i)
		i -= 1


# --- UI Construction -------------------------------------------------------------------------

func _build_ui() -> void:
	var root := UI.full_rect(Control.new())
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var overhead := OverheadOverlay.new()
	overhead.name = "OverheadOverlay"
	add_child(overhead)

	_build_top_bar(root)
	_build_bottom_bar(root)
	_build_minimap(root)
	_build_announcements(root)
	_build_kill_feed(root)
	_build_shop_modal(root)
	_build_scoreboard_modal(root)
	_build_game_over_modal(root)


func _build_top_bar(parent: Control) -> void:
	var top_panel := UI.panel(UITheme.panel_style(Color(0.04, 0.05, 0.08, 0.88), UITheme.BORDER_DIM, 4))
	top_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 320
	top_panel.offset_right = -320
	top_panel.offset_bottom = 44
	parent.add_child(top_panel)

	var hbox := UI.hbox(16)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_panel.add_child(hbox)

	_blue_score_label = UI.label("0", 22, Color(0.4, 0.7, 1.0), true)
	hbox.add_child(_blue_score_label)

	hbox.add_child(UI.label("VS", 14, UITheme.TEXT_DIM, true))

	_red_score_label = UI.label("0", 22, Color(1.0, 0.4, 0.4), true)
	hbox.add_child(_red_score_label)

	hbox.add_child(VSeparator.new())

	_clock_label = UI.label("00:00", 18, UITheme.TEXT, true)
	hbox.add_child(_clock_label)

	hbox.add_child(VSeparator.new())

	_kda_label = UI.label("0 / 0 / 0", 16, UITheme.ACCENT, true)
	hbox.add_child(_kda_label)

	_cs_label = UI.label("0 CS", 14, UITheme.TEXT_DIM)
	hbox.add_child(_cs_label)

	hbox.add_child(VSeparator.new())

	var settings_btn := UI.button("⚙", _open_settings, 32)
	settings_btn.tooltip_text = "Settings (Esc)"
	hbox.add_child(settings_btn)


func _open_settings() -> void:
	if is_instance_valid(_settings_modal):
		_settings_modal.queue_free()
		return
	var overlay := UI.full_rect(Control.new())
	var backdrop := UI.full_rect(ColorRect.new())
	backdrop.color = Color(0.0, 0.0, 0.0, 0.5)
	overlay.add_child(backdrop)
	var center := UI.full_rect(CenterContainer.new())
	overlay.add_child(center)
	var panel := SettingsPanel.new()
	center.add_child(panel)
	panel.closed.connect(overlay.queue_free)
	_settings_modal = overlay
	add_child(overlay)


func _build_bottom_bar(parent: Control) -> void:
	# Recall Channel Bar (Positioned directly above bottom HUD)
	_recall_container = Control.new()
	_recall_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_recall_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_recall_container.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_recall_container.offset_left = -160.0
	_recall_container.offset_right = 160.0
	_recall_container.offset_top = -175.0
	_recall_container.offset_bottom = -142.0
	_recall_container.custom_minimum_size = Vector2(320, 33)
	parent.add_child(_recall_container)

	var recall_panel := UI.panel(UITheme.panel_style(Color(0.04, 0.08, 0.14, 0.95), Color(0.2, 0.7, 1.0, 0.9), 6, 2))
	recall_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_recall_container.add_child(recall_panel)

	_recall_progress = ProgressBar.new()
	_recall_progress.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_recall_progress.show_percentage = false
	var recall_bg := StyleBoxFlat.new()
	recall_bg.bg_color = Color(0.03, 0.05, 0.08, 0.6)
	recall_bg.set_corner_radius_all(4)
	_recall_progress.add_theme_stylebox_override("background", recall_bg)
	var recall_fill := StyleBoxFlat.new()
	recall_fill.bg_color = Color(0.12, 0.65, 0.95, 0.85)
	recall_fill.set_corner_radius_all(4)
	_recall_progress.add_theme_stylebox_override("fill", recall_fill)
	recall_panel.add_child(_recall_progress)

	_recall_timer_label = UI.label("🌀 RECALLING... 4.0s", 12, Color(1.0, 1.0, 1.0), true)
	_recall_timer_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_recall_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_recall_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	recall_panel.add_child(_recall_timer_label)

	_recall_container.visible = false

	var bottom_panel := UI.panel(UITheme.panel_style(Color(0.04, 0.05, 0.08, 0.94), UITheme.BORDER, 8))
	bottom_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bottom_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bottom_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom_panel.offset_left = -370.0
	bottom_panel.offset_right = 370.0
	bottom_panel.offset_top = -130.0
	bottom_panel.offset_bottom = -10.0
	bottom_panel.custom_minimum_size = Vector2(740, 120)
	parent.add_child(bottom_panel)

	var main_row := UI.hbox(12)
	bottom_panel.add_child(main_row)

	# --- Left: Portrait & Stats ---
	var avatar_box := UI.vbox(4)
	main_row.add_child(avatar_box)

	var port_wrapper := Control.new()
	port_wrapper.custom_minimum_size = Vector2(64, 64)
	avatar_box.add_child(port_wrapper)

	_portrait_rect = TextureRect.new()
	_portrait_rect.custom_minimum_size = Vector2(64, 64)
	_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	port_wrapper.add_child(_portrait_rect)

	_level_badge = UI.label("1", 12, UITheme.ACCENT, true)
	_level_badge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_level_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	port_wrapper.add_child(_level_badge)

	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(64, 6)
	_xp_bar.show_percentage = false
	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = Color(0.7, 0.4, 1.0)
	_xp_bar.add_theme_stylebox_override("fill", xp_fill)
	avatar_box.add_child(_xp_bar)

	# Stats grid with vector badges
	var stats_grid := GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 8)
	stats_grid.add_theme_constant_override("v_separation", 3)
	main_row.add_child(stats_grid)

	var b_ad := _make_stat_badge("res://assets/icons/stats/ad.svg", Color(1.0, 0.5, 0.4), "Attack Damage")
	var b_ap := _make_stat_badge("res://assets/icons/stats/ap.svg", Color(0.5, 0.65, 1.0), "Ability Power")
	var b_ar := _make_stat_badge("res://assets/icons/stats/armor.svg", Color(1.0, 0.8, 0.35), "Armor")
	var b_mr := _make_stat_badge("res://assets/icons/stats/mr.svg", Color(0.35, 0.9, 0.85), "Magic Resist")
	var b_as := _make_stat_badge("res://assets/icons/stats/as.svg", Color(0.95, 0.9, 0.4), "Attack Speed")
	var b_ms := _make_stat_badge("res://assets/icons/stats/ms.svg", Color(0.5, 0.9, 0.5), "Movement Speed")

	_ad_label = b_ad["label"]
	_ap_label = b_ap["label"]
	_armor_label = b_ar["label"]
	_mr_label = b_mr["label"]
	_as_label = b_as["label"]
	_ms_label = b_ms["label"]

	stats_grid.add_child(b_ad["box"])
	stats_grid.add_child(b_ap["box"])
	stats_grid.add_child(b_ar["box"])
	stats_grid.add_child(b_mr["box"])
	stats_grid.add_child(b_as["box"])
	stats_grid.add_child(b_ms["box"])

	main_row.add_child(VSeparator.new())

	# --- Center: Bars & Abilities ---
	var center_box := UI.vbox(6)
	center_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_row.add_child(center_box)

	# Health and Mana
	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(0, 18)
	_hp_bar.show_percentage = false
	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.06, 0.08, 0.07, 0.9)
	hp_bg.border_width_left = 1
	hp_bg.border_width_top = 1
	hp_bg.border_width_right = 1
	hp_bg.border_width_bottom = 1
	hp_bg.border_color = Color(0.12, 0.22, 0.14)
	hp_bg.set_corner_radius_all(3)
	_hp_bar.add_theme_stylebox_override("background", hp_bg)
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.16, 0.8, 0.32)
	hp_fill.set_corner_radius_all(3)
	_hp_bar.add_theme_stylebox_override("fill", hp_fill)
	center_box.add_child(_hp_bar)

	_hp_label = UI.outlined(UI.label("0 / 0", 11, Color(1.0, 1.0, 1.0), true), 2)
	_hp_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_bar.add_child(_hp_label)

	_mana_bar = ProgressBar.new()
	_mana_bar.custom_minimum_size = Vector2(0, 14)
	_mana_bar.show_percentage = false
	var mana_bg := StyleBoxFlat.new()
	mana_bg.bg_color = Color(0.05, 0.07, 0.1, 0.9)
	mana_bg.border_width_left = 1
	mana_bg.border_width_top = 1
	mana_bg.border_width_right = 1
	mana_bg.border_width_bottom = 1
	mana_bg.border_color = Color(0.1, 0.18, 0.28)
	mana_bg.set_corner_radius_all(3)
	_mana_bar.add_theme_stylebox_override("background", mana_bg)
	var mana_fill := StyleBoxFlat.new()
	mana_fill.bg_color = Color(0.15, 0.56, 0.94)
	mana_fill.set_corner_radius_all(3)
	_mana_bar.add_theme_stylebox_override("fill", mana_fill)
	center_box.add_child(_mana_bar)

	_mana_label = UI.outlined(UI.label("0 / 0", 10, Color(0.9, 0.95, 1.0), true), 2)
	_mana_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mana_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mana_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mana_bar.add_child(_mana_label)

	# Ability Cards Row
	var kit_row := UI.hbox(8)
	kit_row.alignment = BoxContainer.ALIGNMENT_CENTER
	center_box.add_child(kit_row)

	# Passive
	_passive_card = _build_passive_slot()
	kit_row.add_child(_passive_card)

	# Q, W, E, R
	var keys: Array[String] = ["Q", "W", "E", "R"]
	for i: int in range(4):
		var card_dict := _build_ability_slot(i, keys[i])
		kit_row.add_child(card_dict["root"])
		_ability_cards.append(card_dict)

	main_row.add_child(VSeparator.new())

	# --- Right: Items, Gold, Recall & Shop ---
	var right_box := UI.vbox(4)
	main_row.add_child(right_box)

	var inv_grid := GridContainer.new()
	inv_grid.columns = 3
	inv_grid.add_theme_constant_override("h_separation", 4)
	inv_grid.add_theme_constant_override("v_separation", 4)
	right_box.add_child(inv_grid)

	for i: int in range(6):
		var slot := TextureRect.new()
		slot.custom_minimum_size = Vector2(30, 30)
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var slot_panel := UI.panel(UITheme.panel_style(Color(0.08, 0.1, 0.14), UITheme.BORDER_DIM, 3))
		slot_panel.custom_minimum_size = Vector2(30, 30)
		slot_panel.add_child(slot)
		inv_grid.add_child(slot_panel)
		_item_slots.append(slot)

	var bottom_util_row := UI.hbox(6)
	right_box.add_child(bottom_util_row)

	_gold_label = UI.label("0 g", 13, GameConst.COLOR_GOLD, true)
	bottom_util_row.add_child(_gold_label)

	_shop_button = UI.button("Shop (P)", _toggle_shop, 64)
	_shop_button.add_theme_font_size_override("font_size", 11)
	bottom_util_row.add_child(_shop_button)

	_recall_button = UI.button("", func() -> void:
		if _game and GameConst.RECALL_ENABLED:
			_game.cmd_recall.rpc_id(1)
	, 28)
	_recall_button.icon = load("res://assets/icons/abilities/recall.svg")
	_recall_button.expand_icon = true
	if not GameConst.RECALL_ENABLED:
		_recall_button.tooltip_text = "Recall is disabled in ARAM (Howling Abyss)"
		_recall_button.modulate = Color(0.4, 0.4, 0.45, 0.5)
		_recall_button.disabled = true
	else:
		_recall_button.tooltip_text = "Recall to Fountain (B)"
	bottom_util_row.add_child(_recall_button)


func _make_stat_badge(icon_path: String, color: Color, tooltip: String) -> Dictionary:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	box.tooltip_text = tooltip

	var tex := TextureRect.new()
	tex.custom_minimum_size = Vector2(14, 14)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.texture = load(icon_path)
	box.add_child(tex)

	var val_lbl := UI.label("0", 11, color, true)
	box.add_child(val_lbl)

	return {"box": box, "label": val_lbl}


func _build_passive_slot() -> Control:
	var slot_panel := UI.panel(UITheme.panel_style(Color(0.06, 0.08, 0.12), UITheme.BORDER_DIM, 4))
	slot_panel.custom_minimum_size = Vector2(44, 52)
	slot_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var vbox := UI.vbox(1)
	slot_panel.add_child(vbox)

	var key_lbl := UI.label("P", 10, UITheme.TEXT_DIM, true)
	key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(key_lbl)

	_passive_icon = TextureRect.new()
	_passive_icon.custom_minimum_size = Vector2(32, 32)
	_passive_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_passive_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(_passive_icon)

	_passive_stacks_label = UI.label("", 10, UITheme.ACCENT, true)
	_passive_stacks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_passive_stacks_label)

	return slot_panel


func _build_ability_slot(slot_idx: int, key_str: String) -> Dictionary:
	var slot_root := UI.vbox(2)

	# Level-up "+" button
	var lvl_btn := UI.button("+", func() -> void:
		if _game:
			_game.cmd_level_ability.rpc_id(1, slot_idx)
	, 44)
	lvl_btn.custom_minimum_size.y = 16
	lvl_btn.add_theme_font_size_override("font_size", 12)
	lvl_btn.add_theme_color_override("font_color", UITheme.ACCENT)
	lvl_btn.visible = false
	slot_root.add_child(lvl_btn)

	var card_panel := UI.panel(UITheme.panel_style(Color(0.06, 0.08, 0.12), UITheme.BORDER_DIM, 4))
	card_panel.custom_minimum_size = Vector2(48, 48)
	slot_root.add_child(card_panel)

	var icon_tex := TextureRect.new()
	icon_tex.custom_minimum_size = Vector2(44, 44)
	icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_panel.add_child(icon_tex)

	# Key bind label in top-left with outline
	var key_lbl := UI.outlined(UI.label(key_str, 11, UITheme.ACCENT, true), 3)
	key_lbl.offset_left = 4
	key_lbl.offset_top = 2
	card_panel.add_child(key_lbl)

	# Mana cost label in top-right with outline
	var cost_lbl := UI.outlined(UI.label("", 10, Color(0.45, 0.75, 1.0), true), 3)
	cost_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	cost_lbl.offset_right = -4
	cost_lbl.offset_top = 2
	card_panel.add_child(cost_lbl)

	# Cooldown overlay & countdown
	var cd_overlay := ColorRect.new()
	cd_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cd_overlay.color = Color(0.0, 0.0, 0.0, 0.75)
	cd_overlay.visible = false
	card_panel.add_child(cd_overlay)

	var cd_lbl := UI.label("", 15, Color.WHITE, true)
	cd_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cd_overlay.add_child(cd_lbl)

	# Rank pips row (5 pips for QWE, 3 for R)
	var pips_row := UI.hbox(2)
	pips_row.alignment = BoxContainer.ALIGNMENT_CENTER
	slot_root.add_child(pips_row)

	var max_pips: int = 3 if slot_idx == 3 else 5
	var pips_arr: Array[ColorRect] = []
	for p: int in range(max_pips):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(6, 3)
		pip.color = Color(0.2, 0.25, 0.3)
		pips_row.add_child(pip)
		pips_arr.append(pip)

	return {
		"root": slot_root,
		"card": card_panel,
		"icon": icon_tex,
		"key": key_lbl,
		"cost": cost_lbl,
		"cd_overlay": cd_overlay,
		"cd_label": cd_lbl,
		"level_btn": lvl_btn,
		"pips": pips_arr,
	}


func _build_minimap(parent: Control) -> void:
	var map_panel := UI.panel(UITheme.panel_style(Color(0.02, 0.03, 0.05, 0.9), UITheme.BORDER, 4))
	map_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	map_panel.offset_left = -MINIMAP_W - 14
	map_panel.offset_top = -MINIMAP_H - 14
	map_panel.offset_right = -14
	map_panel.offset_bottom = -14
	map_panel.custom_minimum_size = Vector2(MINIMAP_W, MINIMAP_H)
	parent.add_child(map_panel)

	_minimap_view = Control.new()
	_minimap_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_minimap_view.draw.connect(_draw_minimap)
	_minimap_view.gui_input.connect(_on_minimap_input)
	map_panel.add_child(_minimap_view)


func _draw_minimap() -> void:
	if _minimap_view == null or _game == null:
		return

	var rect := _minimap_view.get_rect()
	var w: float = rect.size.x
	var h: float = rect.size.y

	# 1. Base terrain background
	_minimap_view.draw_rect(Rect2(Vector2.ZERO, rect.size), Color(0.04, 0.06, 0.09, 0.96), true)

	# World to map helper
	var w2m := func(pos: Vector3) -> Vector2:
		var nx: float = clampf((pos.x + Arena.HALF_X) / (Arena.HALF_X * 2.0), 0.0, 1.0)
		var nz: float = clampf((pos.z + Arena.HALF_Z) / (Arena.HALF_Z * 2.0), 0.0, 1.0)
		return Vector2(nx * w, nz * h)

	# 2. River channel (vertical cyan water strip in the center)
	var river_tl: Vector2 = w2m.call(Vector3(-Arena.RIVER_HALF_WIDTH, 0.0, -Arena.HALF_Z))
	var river_br: Vector2 = w2m.call(Vector3(Arena.RIVER_HALF_WIDTH, 0.0, Arena.HALF_Z))
	_minimap_view.draw_rect(Rect2(river_tl.x, 0.0, river_br.x - river_tl.x, h), Color(0.12, 0.38, 0.55, 0.45), true)

	# 3. Main Lane path line
	_minimap_view.draw_line(Vector2(w * 0.08, h * 0.5), Vector2(w * 0.92, h * 0.5), Color(0.24, 0.28, 0.35, 0.65), 3.0)

	# 4. Brush patches (ARAM Lane Bushes)
	for b: Vector2 in [Vector2(-14.0, 3.6), Vector2(0.0, 3.6), Vector2(14.0, 3.6)]:
		var bp: Vector2 = w2m.call(Vector3(b.x, 0.0, b.y))
		_minimap_view.draw_rect(Rect2(bp - Vector2(5.0, 2.0), Vector2(10.0, 4.0)), Color(0.18, 0.48, 0.24, 0.65), true)

	# 5. Fountains
	_minimap_view.draw_circle(w2m.call(Arena.fountain_position(GameConst.TEAM_BLUE)), 4.5, Color(0.2, 0.5, 1.0, 0.7))
	_minimap_view.draw_circle(w2m.call(Arena.fountain_position(GameConst.TEAM_RED)), 4.5, Color(1.0, 0.3, 0.3, 0.7))

	# 6. ARAM Health Relics
	for r: HealthRelic in _game.relics:
		if is_instance_valid(r):
			var rp: Vector2 = w2m.call(r.global_position)
			var r_col: Color = Color(0.2, 0.95, 0.5, 0.9) if r.is_active else Color(0.35, 0.4, 0.45, 0.4)
			_minimap_view.draw_circle(rp, 2.8, r_col)
			if r.is_active:
				_minimap_view.draw_arc(rp, 4.0, 0, TAU, 10, Color(0.3, 1.0, 0.6, 0.8), 1.0)

	# 7. Structures
	for s: Entity in _game.structures:
		var p: Vector2 = w2m.call(s.global_position)
		var c: Color = Color(0.3, 0.3, 0.3) if s.dead else GameConst.team_color(s.team)
		_minimap_view.draw_rect(Rect2(p - Vector2(2.5, 2.5), Vector2(5, 5)), c, true)

	# 8. Minions
	for m: Minion in _game.minions:
		if m.dead:
			continue
		var p: Vector2 = w2m.call(m.global_position)
		_minimap_view.draw_circle(p, 1.5, GameConst.team_color(m.team))

	# 9. Champions
	for c: Champion in _game.champions:
		if c.dead:
			continue
		if c.is_concealed and not c.is_local():
			var local_c: Champion = _champion
			if local_c and local_c.team != c.team:
				var in_same_brush: bool = local_c.current_brush_idx == c.current_brush_idx and c.current_brush_idx != -1
				if not in_same_brush:
					continue
		var p: Vector2 = w2m.call(c.global_position)
		var col: Color = GameConst.team_color(c.team)
		_minimap_view.draw_circle(p, 3.5, col)
		if c.is_local():
			_minimap_view.draw_arc(p, 5.0, 0, TAU, 12, Color(1.0, 0.9, 0.3), 1.5)

	# 10. Camera Frustum / Viewport Box
	if _game.camera_rig:
		# Actual ground footprint of the camera view (a trapezoid for a tilted camera).
		var quad: PackedVector3Array = _game.camera_rig.visible_ground_quad()
		var outline := PackedVector2Array()
		for corner: Vector3 in quad:
			outline.append(w2m.call(corner))
		if outline.size() == 4:
			outline.append(outline[0])
			_minimap_view.draw_polyline(outline, Color(1.0, 0.9, 0.45, 0.75), 1.2)

	# 11. Active Smart Pings
	for ping: Dictionary in _active_pings:
		var p: Vector2 = w2m.call(ping["pos"])
		var col: Color = ping["color"]
		var t_left: float = float(ping["time_left"])
		var alpha: float = clampf(t_left / 1.0, 0.0, 1.0)
		var pulse: float = fmod((4.0 - t_left) * 2.5, 1.0)
		var ring_r: float = 3.0 + pulse * 10.0
		_minimap_view.draw_arc(p, ring_r, 0.0, TAU, 16, Color(col, (1.0 - pulse) * alpha), 2.0)
		_minimap_view.draw_circle(p, 3.5, Color(col, alpha))

	# 12. Outer border frame
	_minimap_view.draw_rect(Rect2(Vector2.ZERO, rect.size), Color(0.4, 0.45, 0.55, 0.8), false, 1.0)


func _minimap_to_world(mouse_pos: Vector2) -> Vector3:
	var map_size: Vector2 = _minimap_view.size
	var nx: float = clampf(mouse_pos.x / maxf(map_size.x, 1.0), 0.0, 1.0)
	var nz: float = clampf(mouse_pos.y / maxf(map_size.y, 1.0), 0.0, 1.0)
	return Vector3(nx * Arena.HALF_X * 2.0 - Arena.HALF_X, 0.0, nz * Arena.HALF_Z * 2.0 - Arena.HALF_Z)


func _on_minimap_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var world_pos := _minimap_to_world(mb.position)

		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if mb.alt_pressed or Input.is_key_pressed(KEY_ALT):
					if _game:
						_game.cmd_ping.rpc_id(1, GameConst.PingType.ALERT, world_pos)
					return
				if mb.ctrl_pressed or Input.is_key_pressed(KEY_CTRL):
					if _game:
						_game.cmd_ping.rpc_id(1, GameConst.PingType.ON_MY_WAY, world_pos)
					return

				_minimap_dragging = true
				_minimap_drag_start_time = Time.get_ticks_msec() / 1000.0
				if _game and _game.camera_rig:
					_game.camera_rig.start_minimap_peek(world_pos)
			else:
				if _minimap_dragging:
					_minimap_dragging = false
					var hold_duration: float = (Time.get_ticks_msec() / 1000.0) - _minimap_drag_start_time
					if _game and _game.camera_rig:
						_game.camera_rig.end_minimap_peek(hold_duration)

		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if mb.alt_pressed or Input.is_key_pressed(KEY_ALT):
				if _game:
					_game.cmd_ping.rpc_id(1, GameConst.PingType.DANGER, world_pos)
				return
			if _game:
				_game.cmd_move.rpc_id(1, world_pos)
				if _game.camera_rig:
					_game.camera_rig.cancel_minimap_peek()

	elif event is InputEventMouseMotion and _minimap_dragging:
		var mm := event as InputEventMouseMotion
		var world_pos := _minimap_to_world(mm.position)
		if _game and _game.camera_rig:
			_game.camera_rig.update_minimap_peek(world_pos)


func _build_announcements(parent: Control) -> void:
	# Centered band between the top bar and the kill feed; wraps instead of running off-screen.
	_announcement_box = Control.new()
	_announcement_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_announcement_box.offset_left = 300
	_announcement_box.offset_right = -300
	_announcement_box.offset_top = 64
	_announcement_box.offset_bottom = 150
	_announcement_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_announcement_box.modulate.a = 0.0
	parent.add_child(_announcement_box)

	_announcement_label = UI.outlined(UI.label("", 28, UITheme.ACCENT, true), 6)
	_announcement_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_announcement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_announcement_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_announcement_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_announcement_box.add_child(_announcement_label)


func _build_kill_feed(parent: Control) -> void:
	_kill_feed_box = UI.vbox(4)
	_kill_feed_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_kill_feed_box.offset_left = -280
	_kill_feed_box.offset_top = 50
	_kill_feed_box.offset_right = -14
	_kill_feed_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_kill_feed_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(_kill_feed_box)


## Adds a fixed-width, click-through row to the kill feed (oldest rows are dropped).
func _add_feed_row(row: PanelContainer, lifetime: float) -> void:
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.clip_contents = true
	for label: Label in row.find_children("*", "Label", true, false):
		if label.text.length() <= 3:
			continue  # separators / assist counters keep their natural width
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.custom_minimum_size.x = 16
	_kill_feed_box.add_child(row)
	while _kill_feed_box.get_child_count() > 6:
		var oldest: Node = _kill_feed_box.get_child(0)
		_kill_feed_box.remove_child(oldest)
		oldest.queue_free()
	get_tree().create_timer(lifetime).timeout.connect(func() -> void:
		if is_instance_valid(row):
			var tw := create_tween()
			tw.tween_property(row, "modulate:a", 0.0, 0.5)
			tw.tween_callback(row.queue_free)
	)


func _build_shop_modal(parent: Control) -> void:
	_shop_modal = UI.panel(UITheme.panel_style(Color(0.05, 0.06, 0.09, 0.98), UITheme.BORDER, 8))
	_shop_modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	# Kept above the bottom action bar (which starts at y = 720 - 130 - bar growth).
	_shop_modal.offset_left = -280
	_shop_modal.offset_top = -300
	_shop_modal.offset_right = 280
	_shop_modal.offset_bottom = 150
	_shop_modal.visible = false
	parent.add_child(_shop_modal)

	var main_vbox := UI.vbox(8)
	_shop_modal.add_child(main_vbox)

	var hdr := UI.hbox(8)
	main_vbox.add_child(hdr)
	hdr.add_child(UI.label("SHOP", 18, UITheme.ACCENT, true))
	hdr.add_child(UI.spacer(true))
	var close_btn := UI.button("X", _toggle_shop, 30)
	hdr.add_child(close_btn)

	main_vbox.add_child(HSeparator.new())

	var body := UI.hbox(12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(body)

	# Left: Item List
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(280, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)

	_shop_item_list = UI.vbox(4)
	_shop_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_shop_item_list)

	for item_id: String in ItemDB.SHOP_ORDER:
		var item_info: Dictionary = ItemDB.get_item(item_id)
		var item_btn := UI.button("%s - %dg" % [item_info["name"], item_info["cost"]], func() -> void:
			_select_shop_item(item_id)
		)
		item_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_shop_item_list.add_child(item_btn)

	# Right: Item Details & Buy/Sell
	var details_box := UI.vbox(8)
	details_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(details_box)

	_shop_details_label = UI.label("Select an item to view stats", 13, UITheme.TEXT)
	_shop_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_shop_details_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_box.add_child(_shop_details_label)

	_shop_buy_btn = UI.button("BUY ITEM", _buy_selected_item, 120)
	_shop_buy_btn.disabled = true
	details_box.add_child(_shop_buy_btn)

	details_box.add_child(HSeparator.new())
	details_box.add_child(UI.label("YOUR INVENTORY (Click to Sell)", 11, UITheme.TEXT_DIM))

	# Wraps onto multiple lines so a full inventory never widens the shop window.
	_shop_inv_row = HFlowContainer.new()
	_shop_inv_row.add_theme_constant_override("h_separation", 4)
	_shop_inv_row.add_theme_constant_override("v_separation", 4)
	_shop_inv_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_box.add_child(_shop_inv_row)


func _build_scoreboard_modal(parent: Control) -> void:
	_scoreboard_modal = UI.panel(UITheme.panel_style(Color(0.04, 0.05, 0.08, 0.96), UITheme.BORDER, 8))
	_scoreboard_modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_scoreboard_modal.offset_left = -380
	_scoreboard_modal.offset_top = -290
	_scoreboard_modal.offset_right = 380
	_scoreboard_modal.offset_bottom = 150
	_scoreboard_modal.visible = false
	parent.add_child(_scoreboard_modal)

	var main_vbox := UI.vbox(10)
	_scoreboard_modal.add_child(main_vbox)

	var hdr := UI.hbox(8)
	main_vbox.add_child(hdr)
	hdr.add_child(UI.label("SCOREBOARD (TAB)", 18, UITheme.ACCENT, true))
	hdr.add_child(UI.spacer(true))
	var close_btn := UI.button("X", func() -> void: _scoreboard_modal.visible = false, 30)
	hdr.add_child(close_btn)

	main_vbox.add_child(HSeparator.new())

	var teams_hbox := UI.hbox(16)
	teams_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(teams_hbox)

	var blue_box := UI.vbox(6)
	blue_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	teams_hbox.add_child(blue_box)
	blue_box.add_child(UI.label("BLUE TEAM", 14, Color(0.4, 0.7, 1.0), true))
	_scoreboard_blue = UI.vbox(4)
	blue_box.add_child(_scoreboard_blue)

	var red_box := UI.vbox(6)
	red_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	teams_hbox.add_child(red_box)
	red_box.add_child(UI.label("RED TEAM", 14, Color(1.0, 0.4, 0.4), true))
	_scoreboard_red = UI.vbox(4)
	red_box.add_child(_scoreboard_red)


func _build_game_over_modal(parent: Control) -> void:
	_game_over_modal = UI.panel(UITheme.panel_style(Color(0.04, 0.05, 0.08, 0.98), UITheme.BORDER, 10))
	_game_over_modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_game_over_modal.offset_left = -260
	_game_over_modal.offset_top = -140
	_game_over_modal.offset_right = 260
	_game_over_modal.offset_bottom = 140
	_game_over_modal.visible = false
	parent.add_child(_game_over_modal)

	var vbox := UI.vbox(14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_game_over_modal.add_child(vbox)

	_game_over_title = UI.outlined(UI.label("VICTORY", 48, UITheme.ACCENT, true), 8)
	_game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_game_over_title)

	_game_over_details = UI.label("Match finished", 14, UITheme.TEXT)
	_game_over_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_game_over_details)

	var lobby_btn := UI.button("RETURN TO LOBBY", func() -> void:
		if NetworkManager.is_host():
			NetworkManager.return_to_lobby()
		else:
			NetworkManager.leave()
	, 180)
	lobby_btn.custom_minimum_size.y = 40
	vbox.add_child(lobby_btn)


# --- Updates ---------------------------------------------------------------------------------

func _update_kit() -> void:
	if _champion == null:
		return
	var data: ChampionData = _champion.data
	if data == null:
		return

	if data.portrait:
		_portrait_rect.texture = data.portrait

	# Passive
	if data.passive:
		if _passive_icon and data.passive.icon:
			_passive_icon.texture = data.passive.icon
		_passive_card.tooltip_text = "%s\n%s" % [data.passive.display_name, data.passive.description]

	# Abilities
	for i: int in range(mini(data.abilities.size(), _ability_cards.size())):
		var ab: AbilityData = data.abilities[i]
		var card: Dictionary = _ability_cards[i]
		if ab:
			if ab.icon:
				(card["icon"] as TextureRect).texture = ab.icon
			(card["card"] as Control).tooltip_text = "%s\nCost: %d Mana | CD: %.1fs\n%s" % [
				ab.display_name, int(ab.get_mana_cost(1)), ab.get_cooldown(1), ab.description
			]


func _update_clock_and_score() -> void:
	if _game == null:
		return
	var secs: int = int(_game.game_time)
	_clock_label.text = "%02d:%02d" % [secs / 60, secs % 60]

	var blue_kills: int = 0
	var red_kills: int = 0
	for c: Champion in _game.champions:
		if c.team == GameConst.TEAM_BLUE:
			blue_kills += c.kills
		else:
			red_kills += c.kills

	_blue_score_label.text = str(blue_kills)
	_red_score_label.text = str(red_kills)


func _update_bars() -> void:
	_level_badge.text = str(_champion.level)
	_xp_bar.max_value = maxf(GameConst.xp_to_next_level(_champion.level), 1.0)
	_xp_bar.value = _champion.xp

	_hp_bar.max_value = _champion.max_health
	_hp_bar.value = _champion.health
	_hp_label.text = "%d / %d" % [int(_champion.health), int(_champion.max_health)]

	_mana_bar.max_value = _champion.max_mana
	_mana_bar.value = _champion.mana
	_mana_label.text = "%d / %d" % [int(_champion.mana), int(_champion.max_mana)]

	_kda_label.text = "%d / %d / %d" % [_champion.kills, _champion.deaths, _champion.assists]
	_cs_label.text = "%d CS" % _champion.creep_score
	_gold_label.text = "%d g" % _champion.gold

	# Passive stacks
	if _passive_stacks_label:
		_passive_stacks_label.text = str(_champion.passive_stacks) if _champion.passive_stacks > 0 else ""

	# Stats block
	if _champion.stat_block.size() >= 8:
		_ad_label.text = "%d" % int(_champion.stat_block[0])
		_ap_label.text = "%d" % int(_champion.stat_block[1])
		_armor_label.text = "%d" % int(_champion.stat_block[2])
		_mr_label.text = "%d" % int(_champion.stat_block[3])
		_as_label.text = "%.2f" % _champion.stat_block[4]
		_ms_label.text = "%d" % int(_champion.stat_block[5] * 10.0)


func _update_abilities() -> void:
	var can_level: bool = _champion.skill_points > 0
	for i: int in range(mini(_ability_cards.size(), _champion.ability_ranks.size())):
		var card: Dictionary = _ability_cards[i]
		var rank: int = _champion.ability_ranks[i]
		var ab: AbilityData = _champion.get_ability(i)

		# Level up button
		var lvl_btn: Button = card["level_btn"]
		var can_learn_this: bool = can_level and (
			(i < 3 and rank < 5 and _champion.level >= rank * 2) or
			(i == 3 and rank < 3 and _champion.level >= 6 + rank * 5)
		)
		lvl_btn.visible = can_learn_this

		# Mana cost
		if ab:
			var cost: int = int(ab.get_mana_cost(rank))
			(card["cost"] as Label).text = str(cost) if cost > 0 else ""

		# Cooldown
		var cd_rem: float = _champion.get_cooldown_remaining(i)
		var cd_overlay: ColorRect = card["cd_overlay"]
		var cd_lbl: Label = card["cd_label"]
		if cd_rem > 0.05:
			cd_overlay.visible = true
			cd_lbl.text = "%.1f" % cd_rem if cd_rem < 3.0 else str(ceili(cd_rem))
		else:
			cd_overlay.visible = false

		# Unlocked & Mana check (Grey out unlearned abilities)
		var has_mana: bool = ab == null or _champion.mana >= ab.get_mana_cost(rank)
		if rank == 0:
			(card["card"] as Control).modulate = Color(0.36, 0.38, 0.42, 0.8)
		elif not has_mana:
			(card["card"] as Control).modulate = Color(0.5, 0.6, 0.9, 0.85)
		else:
			(card["card"] as Control).modulate = Color(1.0, 1.0, 1.0, 1.0)

		# Pips
		var pips: Array = card["pips"]
		for p_idx: int in range(pips.size()):
			var pip: ColorRect = pips[p_idx]
			pip.color = UITheme.ACCENT if p_idx < rank else Color(0.2, 0.25, 0.3)


func _update_inventory() -> void:
	for i: int in range(_item_slots.size()):
		var slot: TextureRect = _item_slots[i]
		if i < _champion.items.size() and not _champion.items[i].is_empty():
			var item_id: String = _champion.items[i]
			slot.texture = ItemDB.icon(item_id)
			slot.tooltip_text = "%s\nSell: %dg" % [ItemDB.display_name(item_id), int(ItemDB.cost(item_id) * 0.7)]
		else:
			slot.texture = null
			slot.tooltip_text = "Empty Slot"


func _update_recall() -> void:
	if _recall_container == null:
		return
	if _champion != null and _champion.recall_end > 0.0 and Game.current != null:
		var now: float = Game.current.game_time
		var rem: float = _champion.recall_end - now
		if rem > 0.0:
			_recall_container.visible = true
			var total: float = GameConst.RECALL_DURATION
			var progress: float = clampf((total - rem) / total, 0.0, 1.0)
			_recall_progress.value = progress * 100.0
			_recall_timer_label.text = "🌀 RECALLING... %.1fs" % rem
			return
	_recall_container.visible = false


# --- Shop Logic ------------------------------------------------------------------------------

func _toggle_shop() -> void:
	_shop_modal.visible = not _shop_modal.visible
	if _shop_modal.visible:
		_refresh_shop_inv()


func _select_shop_item(item_id: String) -> void:
	_shop_selected_item = item_id
	var item: Dictionary = ItemDB.get_item(item_id)
	var stats_desc: String = ""
	for s_key: String in item.get("stats", {}):
		stats_desc += "\n" + ItemDB.format_stat(s_key, item["stats"][s_key])

	var can_shop_state: bool = _champion != null and _champion.can_shop()
	var can_afford: bool = _champion != null and _champion.gold >= item["cost"] and _champion.items.size() < 6
	_shop_buy_btn.disabled = not (can_shop_state and can_afford)

	if not can_shop_state:
		_shop_details_label.text = "%s\nCost: %d Gold%s\n[color=#ff5555]ARAM: You can only buy items when dead![/color]" % [item["name"], item["cost"], stats_desc]
	else:
		_shop_details_label.text = "%s\nCost: %d Gold%s" % [item["name"], item["cost"], stats_desc]


func _buy_selected_item() -> void:
	if _game and not _shop_selected_item.is_empty():
		_game.cmd_buy.rpc_id(1, _shop_selected_item)
		await get_tree().create_timer(0.15).timeout
		_refresh_shop_inv()
		if not _shop_selected_item.is_empty():
			_select_shop_item(_shop_selected_item)


func _refresh_shop_inv() -> void:
	for child: Node in _shop_inv_row.get_children():
		child.queue_free()
	if _champion == null:
		return
	for i: int in range(_champion.items.size()):
		var item_id: String = _champion.items[i]
		if item_id.is_empty():
			continue
		var btn := UI.button("Sell %s" % ItemDB.display_name(item_id), func() -> void:
			if _game:
				_game.cmd_sell.rpc_id(1, i)
				await get_tree().create_timer(0.15).timeout
				_refresh_shop_inv()
		)
		btn.add_theme_font_size_override("font_size", 10)
		_shop_inv_row.add_child(btn)


# --- Scoreboard Logic -------------------------------------------------------------------------

func _refresh_scoreboard() -> void:
	for child: Node in _scoreboard_blue.get_children():
		child.queue_free()
	for child: Node in _scoreboard_red.get_children():
		child.queue_free()
	if _game == null:
		return

	for c: Champion in _game.champions:
		var target_col: VBoxContainer = _scoreboard_blue if c.team == GameConst.TEAM_BLUE else _scoreboard_red
		var row := UI.hbox(8)
		row.add_child(UI.label("Lv%d" % c.level, 12, UITheme.ACCENT))
		row.add_child(UI.label(c.player_name, 13, UITheme.TEXT, c.is_local()))
		row.add_child(UI.spacer(true))
		row.add_child(UI.label("%d/%d/%d" % [c.kills, c.deaths, c.assists], 13, UITheme.TEXT))
		row.add_child(UI.label("%d CS" % c.creep_score, 12, UITheme.TEXT_DIM))
		row.add_child(UI.label("%dg" % c.gold, 12, GameConst.COLOR_GOLD))
		target_col.add_child(row)


# --- Events -----------------------------------------------------------------------------------

func _on_announcement(text: String, color: Color, big: bool) -> void:
	if _announcement_tween:
		_announcement_tween.kill()
	_announcement_label.text = text
	_announcement_label.add_theme_color_override("font_color", color)
	_announcement_label.add_theme_font_size_override("font_size", 34 if big else 22)
	_announcement_box.pivot_offset = Vector2(_announcement_box.size.x * 0.5, 20.0)
	_announcement_box.scale = Vector2.ONE * (1.3 if big else 1.1)
	_announcement_box.modulate.a = 1.0

	_announcement_tween = create_tween()
	_announcement_tween.tween_property(_announcement_box, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_announcement_tween.tween_interval(2.5)
	_announcement_tween.tween_property(_announcement_box, "modulate:a", 0.0, 0.6)


func _on_kill_feed(entry: Dictionary) -> void:
	var row := UI.panel(UITheme.panel_style(Color(0.06, 0.08, 0.12, 0.9), UITheme.BORDER_DIM, 3))
	var hbox := UI.hbox(6)
	row.add_child(hbox)

	var k_color: Color = GameConst.team_color(int(entry["killer_team"]))
	var v_color: Color = GameConst.team_color(int(entry["victim_team"]))

	hbox.add_child(UI.label(String(entry["killer"]), 12, k_color, true))
	hbox.add_child(UI.label("⚔️", 11, UITheme.TEXT_DIM))
	hbox.add_child(UI.label(String(entry["victim"]), 12, v_color, true))

	if int(entry.get("assists", 0)) > 0:
		hbox.add_child(UI.label("+%d" % int(entry["assists"]), 10, UITheme.TEXT_DIM))

	_add_feed_row(row, 6.0)


func _on_phase_changed(phase: int) -> void:
	if phase == Game.Phase.ENDED:
		_game_over_modal.visible = true
		var won: bool = _champion != null and _champion.team == _game.winner_team
		_game_over_title.text = "VICTORY" if won else "DEFEAT"
		_game_over_title.add_theme_color_override("font_color", UITheme.ACCENT if won else Color(1.0, 0.3, 0.3))
		var mins: int = int(_game.game_time) / 60
		var secs: int = int(_game.game_time) % 60
		_game_over_details.text = "Match Duration: %02d:%02d" % [mins, secs]


func _on_command_failed(_slot: int, reason: String) -> void:
	var msg := reason
	match reason:
		"cooldown": msg = "Ability on Cooldown!"
		"mana": msg = "Not Enough Mana!"
		"stunned": msg = "Cannot Cast While Stunned!"
		"no_target": msg = "Requires a Target!"
		"not_learned": msg = "Ability Not Learned!"
	_on_announcement(msg, Color(1.0, 0.4, 0.4), false)


func _on_ping_received(sender_name: String, sender_team: int, ping_type: int, world_pos: Vector3) -> void:
	var col: Color = GameConst.ping_color(ping_type)
	_active_pings.append({
		"pos": world_pos,
		"color": col,
		"type": ping_type,
		"time_left": 4.0,
	})

	var label_text: String = GameConst.ping_label(ping_type)
	var row := UI.panel(UITheme.panel_style(Color(0.05, 0.07, 0.1, 0.92), col, 3))
	var hbox := UI.hbox(6)
	row.add_child(hbox)

	var team_col: Color = GameConst.team_color(sender_team)
	hbox.add_child(UI.label(sender_name, 12, team_col, true))
	hbox.add_child(UI.label("signaled:", 11, UITheme.TEXT_DIM))
	hbox.add_child(UI.label(label_text, 12, col, true))

	_add_feed_row(row, 4.5)
