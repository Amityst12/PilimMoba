class_name Lobby
extends Node3D
## League of Legends ARAM-style Champion Select screen.
## Strict 1280x720 layout: Left Order (Blue), Center Champion Grid & Spotlight, Right Chaos (Red).

@onready var _camera: Camera3D = $LobbyCamera
@onready var _ui: CanvasLayer = $UI

# Theme Colors
const COLOR_GOLD := Color(0.85, 0.72, 0.42)
const COLOR_GOLD_BRIGHT := Color(0.98, 0.88, 0.55)
const COLOR_GOLD_DIM := Color(0.55, 0.45, 0.25)
const COLOR_HEX_CYAN := Color(0.08, 0.82, 0.78)
const COLOR_BLUE_TEAM := Color(0.25, 0.6, 1.0)
const COLOR_RED_TEAM := Color(1.0, 0.35, 0.35)
const COLOR_BG_DARK := Color(0.02, 0.04, 0.07, 0.94)

# UI Elements
var _blue_container: VBoxContainer
var _red_container: VBoxContainer
var _blue_count_label: Label
var _red_count_label: Label
var _lock_in_button: Button
var _status_label: Label
var _chat_log: RichTextLabel
var _chat_input: LineEdit
var _search_input: LineEdit
var _grid_container: GridContainer
var _bg_splash: TextureRect

# Selection & Spotlight
var _champ_cards: Dictionary = {}
var _selected_preview_id: StringName = &""
var _current_role_filter: String = "ALL"
var _spotlight_name: Label
var _spotlight_title: Label
var _spotlight_role: Label
var _spotlight_desc: Label
var _abilities_container: HBoxContainer
var _ability_desc_label: Label
var _timer_label: Label
var _countdown: float = 30.0
var _orbit: float = 1.2
var _is_locked_in: bool = false


func _ready() -> void:
	get_tree().paused = false
	_build_ui()
	NetworkManager.lobby_changed.connect(_refresh)
	NetworkManager.chat_received.connect(_on_chat)
	NetworkManager.status_changed.connect(_on_status)
	_refresh()
	if NetworkManager.launch_options.has("autostart"):
		get_tree().create_timer(0.4).timeout.connect(func() -> void:
			if NetworkManager.is_host():
				NetworkManager.start_match()
		)


func _process(delta: float) -> void:
	_orbit += delta * 0.03
	var focus := Vector3(0.0, 0.0, 0.0)
	_camera.global_position = focus + Vector3(sin(_orbit) * 35.0, 24.0, cos(_orbit) * 35.0)
	_camera.look_at(focus, Vector3.UP)

	# ARAM Timer Tick
	if _countdown > 0.0:
		_countdown = maxf(0.0, _countdown - delta)
		if _timer_label:
			_timer_label.text = "%02d" % int(ceilf(_countdown))
			if _countdown <= 5.0:
				_timer_label.modulate = Color(1.0, 0.3, 0.3)
			else:
				_timer_label.modulate = COLOR_GOLD_BRIGHT


func _build_ui() -> void:
	# 1. Full-screen root container (strictly clamped to viewport)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.clip_contents = true
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)

	# Dark Atmospheric Background
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.03, 0.05, 0.88)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)

	# Subtle Champion Splash Art Backdrop (fades behind champ select)
	_bg_splash = TextureRect.new()
	_bg_splash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_splash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_splash.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_splash.modulate = Color(1.0, 1.0, 1.0, 0.12)
	_bg_splash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_bg_splash)

	# Main Margin Container (14px padding to guarantee 100% on-screen visibility)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	root.add_child(margin)

	var main_vbox := UI.vbox(6)
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(main_vbox)

	# --- 1. TOP HEADER (LoL ARAM Style) ---
	_build_header(main_vbox)

	# --- 2. MAIN BODY (Blue Team | Center LoL Select | Red Team) ---
	var body := UI.hbox(10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(body)

	# Left Column: Order / Blue Team (Fixed 225px)
	_build_blue_column(body)

	# Center Column: ARAM Champion Grid & Spotlight (~770px available)
	_build_center_column(body)

	# Right Column: Chaos / Red Team (Fixed 225px)
	_build_red_column(body)

	# --- 3. BOTTOM FOOTER STATUS ---
	var footer := UI.hbox(8)
	footer.custom_minimum_size.y = 20
	main_vbox.add_child(footer)

	_status_label = UI.label("Select your champion for the Single-Lane bridge!", 12, COLOR_GOLD_DIM)
	footer.add_child(_status_label)
	footer.add_child(UI.spacer(true))

	var mode_label := UI.label("HOWLING RIFT  •  5v5 ARAM", 11, COLOR_HEX_CYAN)
	footer.add_child(mode_label)


# =========================================================================
# Header Construction
# =========================================================================
func _build_header(parent: VBoxContainer) -> void:
	var header := UI.hbox(10)
	header.custom_minimum_size.y = 44
	parent.add_child(header)

	# Left: Game branding & Leave button
	var left_box := UI.hbox(8)
	left_box.custom_minimum_size.x = 220
	header.add_child(left_box)

	var title := UI.outlined(UI.label("PILIM MOBA", 20, COLOR_GOLD, true), 3)
	left_box.add_child(title)

	var leave_btn := UI.button("✕ Leave", _on_leave, 70)
	leave_btn.add_theme_font_size_override("font_size", 11)
	left_box.add_child(leave_btn)

	header.add_child(UI.spacer(true))

	# Center: LoL ARAM Banner & Countdown Timer
	var center_banner := UI.hbox(12)
	center_banner.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(center_banner)

	var aram_tag := UI.label("⚔️ ARAM - ALL MID ⚔️", 18, COLOR_GOLD_BRIGHT, true)
	aram_tag = UI.outlined(aram_tag, 4)
	center_banner.add_child(aram_tag)

	# Circular timer box
	var timer_panel := UI.panel(UITheme.panel_style(Color(0.05, 0.08, 0.12, 0.95), COLOR_GOLD, 16, 2))
	timer_panel.custom_minimum_size = Vector2(40, 36)
	center_banner.add_child(timer_panel)

	_timer_label = UI.label("30", 17, COLOR_GOLD_BRIGHT, true)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_panel.add_child(_timer_label)

	header.add_child(UI.spacer(true))

	# Right: Host / Network Info Badge
	var right_box := UI.hbox(8)
	right_box.custom_minimum_size.x = 220
	right_box.alignment = BoxContainer.ALIGNMENT_END
	header.add_child(right_box)

	var mode_text := "Practice (Single Lane)"
	if NetworkManager.mode == NetworkManager.Mode.HOST:
		mode_text = "Host :%d" % NetworkManager.host_port
	elif NetworkManager.mode == NetworkManager.Mode.CLIENT:
		mode_text = "Client"
	var info_pill := UI.panel(UITheme.panel_style(Color(0.06, 0.1, 0.16, 0.85), COLOR_GOLD_DIM, 10, 1))
	var pill_lbl := UI.label(mode_text, 11, COLOR_GOLD)
	info_pill.add_child(pill_lbl)
	right_box.add_child(info_pill)


# =========================================================================
# Blue Team Column (Order)
# =========================================================================
func _build_blue_column(parent: HBoxContainer) -> void:
	var blue_panel := UI.panel(UITheme.panel_style(Color(0.03, 0.07, 0.13, 0.94), COLOR_BLUE_TEAM, 6, 2))
	blue_panel.custom_minimum_size = Vector2(225, 0)
	parent.add_child(blue_panel)

	var blue_box := UI.vbox(4)
	blue_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	blue_panel.add_child(blue_box)

	# Team Header
	var hdr := UI.hbox(4)
	blue_box.add_child(hdr)
	hdr.add_child(UI.label("ORDER (BLUE)", 14, COLOR_BLUE_TEAM, true))
	hdr.add_child(UI.spacer(true))
	_blue_count_label = UI.label("0/5", 12, UITheme.TEXT_DIM)
	hdr.add_child(_blue_count_label)

	blue_box.add_child(HSeparator.new())

	# Player Slots List
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	blue_box.add_child(scroll)

	_blue_container = UI.vbox(4)
	_blue_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_blue_container)

	# Action Buttons (Switch to Blue / + Bot)
	var btn_row := UI.hbox(4)
	blue_box.add_child(btn_row)

	var switch_btn := UI.button("Switch Blue", func() -> void: NetworkManager.request_team(GameConst.TEAM_BLUE))
	switch_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	switch_btn.add_theme_font_size_override("font_size", 11)
	btn_row.add_child(switch_btn)

	if NetworkManager.is_host():
		var add_bot := UI.button("+ Bot", func() -> void: NetworkManager.request_add_bot(GameConst.TEAM_BLUE), 55)
		add_bot.add_theme_font_size_override("font_size", 11)
		btn_row.add_child(add_bot)

	# Docked Team Chat at bottom of left column
	blue_box.add_child(HSeparator.new())
	var chat_box := UI.vbox(2)
	chat_box.custom_minimum_size.y = 110
	blue_box.add_child(chat_box)

	var chat_hdr := UI.label("TEAM CHAT", 10, COLOR_GOLD_DIM, true)
	chat_box.add_child(chat_hdr)

	_chat_log = RichTextLabel.new()
	_chat_log.bbcode_enabled = true
	_chat_log.scroll_following = true
	_chat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chat_log.focus_mode = Control.FOCUS_NONE
	_chat_log.add_theme_font_size_override("normal_font_size", 11)
	chat_box.add_child(_chat_log)

	var chat_input_row := UI.hbox(4)
	chat_box.add_child(chat_input_row)

	_chat_input = LineEdit.new()
	_chat_input.placeholder_text = "Chat..."
	_chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_input.add_theme_font_size_override("font_size", 11)
	_chat_input.text_submitted.connect(_on_send_chat)
	chat_input_row.add_child(_chat_input)


# =========================================================================
# Red Team Column (Chaos)
# =========================================================================
func _build_red_column(parent: HBoxContainer) -> void:
	var red_panel := UI.panel(UITheme.panel_style(Color(0.12, 0.04, 0.04, 0.94), COLOR_RED_TEAM, 6, 2))
	red_panel.custom_minimum_size = Vector2(225, 0)
	parent.add_child(red_panel)

	var red_box := UI.vbox(4)
	red_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	red_panel.add_child(red_box)

	# Team Header
	var hdr := UI.hbox(4)
	red_box.add_child(hdr)
	hdr.add_child(UI.label("CHAOS (RED)", 14, COLOR_RED_TEAM, true))
	hdr.add_child(UI.spacer(true))
	_red_count_label = UI.label("0/5", 12, UITheme.TEXT_DIM)
	hdr.add_child(_red_count_label)

	red_box.add_child(HSeparator.new())

	# Player Slots List
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	red_box.add_child(scroll)

	_red_container = UI.vbox(4)
	_red_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_red_container)

	# Action Buttons (Switch to Red / + Bot)
	var btn_row := UI.hbox(4)
	red_box.add_child(btn_row)

	var switch_btn := UI.button("Switch Red", func() -> void: NetworkManager.request_team(GameConst.TEAM_RED))
	switch_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	switch_btn.add_theme_font_size_override("font_size", 11)
	btn_row.add_child(switch_btn)

	if NetworkManager.is_host():
		var add_bot := UI.button("+ Bot", func() -> void: NetworkManager.request_add_bot(GameConst.TEAM_RED), 55)
		add_bot.add_theme_font_size_override("font_size", 11)
		btn_row.add_child(add_bot)


# =========================================================================
# Center Column: LoL ARAM Champion Select & Spotlight
# =========================================================================
func _build_center_column(parent: HBoxContainer) -> void:
	var center_box := UI.vbox(6)
	center_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(center_box)

	# 1. Search & Role Filter Bar
	var filter_bar := UI.hbox(6)
	filter_bar.custom_minimum_size.y = 32
	center_box.add_child(filter_bar)

	_search_input = LineEdit.new()
	_search_input.placeholder_text = "🔍 Search champion..."
	_search_input.custom_minimum_size.x = 180
	_search_input.add_theme_font_size_override("font_size", 12)
	_search_input.text_changed.connect(func(_new_text: String) -> void: _filter_grid())
	filter_bar.add_child(_search_input)

	# Role Filter Buttons
	var roles: Array[String] = ["ALL", "FIGHTER", "TANK", "MAGE", "SUPPORT"]
	for r: String in roles:
		var r_btn := UI.button(r, func() -> void:
			_current_role_filter = r
			_filter_grid()
		)
		r_btn.add_theme_font_size_override("font_size", 11)
		filter_bar.add_child(r_btn)

	filter_bar.add_child(UI.spacer(true))

	# ARAM Reroll Dice Button 🎲
	var reroll_btn := UI.button("🎲 REROLL", _on_reroll_champion, 95)
	reroll_btn.add_theme_color_override("font_color", COLOR_HEX_CYAN)
	reroll_btn.add_theme_font_size_override("font_size", 12)
	reroll_btn.tooltip_text = "Reroll a random champion for ARAM (All Mid)!"
	filter_bar.add_child(reroll_btn)

	# 2. Champion Grid Frame (LoL Style Grid of Champion Cards)
	var grid_panel := UI.panel(UITheme.panel_style(Color(0.03, 0.05, 0.08, 0.9), COLOR_GOLD_DIM, 6, 1))
	grid_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_box.add_child(grid_panel)

	var grid_scroll := ScrollContainer.new()
	grid_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	grid_panel.add_child(grid_scroll)

	_grid_container = GridContainer.new()
	_grid_container.columns = 7
	_grid_container.add_theme_constant_override("h_separation", 10)
	_grid_container.add_theme_constant_override("v_separation", 10)
	_grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_scroll.add_child(_grid_container)

	_champ_cards.clear()
	for champ_id: StringName in ChampionDB.IDS:
		var champ_data: ChampionData = ChampionDB.get_champion(champ_id)
		if champ_data == null:
			continue
		var card := _build_champ_card(champ_data)
		_grid_container.add_child(card)
		_champ_cards[champ_id] = card

	# 3. Selected Champion Spotlight & Abilities Box (Bounded height to avoid overflow)
	var spotlight_panel := UI.panel(UITheme.panel_style(Color(0.04, 0.07, 0.12, 0.95), COLOR_GOLD, 6, 1))
	spotlight_panel.custom_minimum_size.y = 120
	center_box.add_child(spotlight_panel)

	var spot_vbox := UI.vbox(4)
	spotlight_panel.add_child(spot_vbox)

	var spot_top_row := UI.hbox(10)
	spot_vbox.add_child(spot_top_row)

	_spotlight_name = UI.label("SELECT A CHAMPION", 18, COLOR_GOLD_BRIGHT, true)
	spot_top_row.add_child(_spotlight_name)

	_spotlight_title = UI.label("", 13, COLOR_HEX_CYAN)
	spot_top_row.add_child(_spotlight_title)

	_spotlight_role = UI.label("", 12, COLOR_GOLD_DIM)
	spot_top_row.add_child(_spotlight_role)

	spot_top_row.add_child(UI.spacer(true))

	# Abilities Row (5 neat square buttons [P] [Q] [W] [E] [R])
	_abilities_container = UI.hbox(6)
	spot_top_row.add_child(_abilities_container)

	# Bounded Ability Description Label (strict autowrap to NEVER exceed width)
	_ability_desc_label = UI.label("", 11, UITheme.TEXT)
	_ability_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ability_desc_label.custom_minimum_size = Vector2(0, 36)
	_ability_desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spot_vbox.add_child(_ability_desc_label)

	# 4. Prominent LoL "LOCK IN" Button (Always Centered and Accessible!)
	var lock_row := UI.hbox(8)
	lock_row.alignment = BoxContainer.ALIGNMENT_CENTER
	center_box.add_child(lock_row)

	_lock_in_button = Button.new()
	_lock_in_button.custom_minimum_size = Vector2(260, 42)
	_lock_in_button.focus_mode = Control.FOCUS_NONE
	_lock_in_button.text = "LOCK IN"
	_lock_in_button.add_theme_font_size_override("font_size", 16)
	_lock_in_button.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05))

	var gold_style := StyleBoxFlat.new()
	gold_style.bg_color = COLOR_GOLD_BRIGHT
	gold_style.border_color = Color(1.0, 0.95, 0.7)
	gold_style.set_border_width_all(2)
	gold_style.set_corner_radius_all(4)
	_lock_in_button.add_theme_stylebox_override("normal", gold_style)

	var gold_hover := gold_style.duplicate() as StyleBoxFlat
	gold_hover.bg_color = Color(1.0, 0.95, 0.65)
	_lock_in_button.add_theme_stylebox_override("hover", gold_hover)

	_lock_in_button.pressed.connect(_on_lock_in_pressed)
	lock_row.add_child(_lock_in_button)


# =========================================================================
# Champion Card Tile Builder (Grid Item)
# =========================================================================
func _build_champ_card(data: ChampionData) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(80, 92)
	btn.focus_mode = Control.FOCUS_NONE
	btn.flat = true

	var vbox := UI.vbox(2)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	# Framed Portrait
	var frame := PanelContainer.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.08, 0.1, 0.15, 0.9)
	frame_style.border_color = COLOR_GOLD_DIM
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(4)
	frame.add_theme_stylebox_override("panel", frame_style)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(frame)

	if data.portrait:
		var tex_rect := UI.texture_rect(data.portrait, Vector2(60, 60))
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(tex_rect)

	var name_lbl := UI.label(data.display_name, 11, UITheme.TEXT, true)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	btn.mouse_entered.connect(func() -> void:
		frame_style.border_color = COLOR_GOLD_BRIGHT
		Sfx.play("hover", -14.0, 0.02)
	)
	btn.mouse_exited.connect(func() -> void:
		if StringName(NetworkManager.local_player().get("champion", "")) != data.id:
			frame_style.border_color = COLOR_GOLD_DIM
	)

	btn.pressed.connect(func() -> void:
		NetworkManager.request_champion(String(data.id))
		_select_preview(data.id)
		Sfx.play("click", -6.0)
	)

	return btn


# =========================================================================
# Spotlight & Ability Inspection
# =========================================================================
func _select_preview(champion_id: StringName) -> void:
	_selected_preview_id = champion_id
	var data: ChampionData = ChampionDB.get_champion(champion_id)
	if data == null:
		return

	_spotlight_name.text = data.display_name.to_upper()
	_spotlight_title.text = "— %s" % data.title
	_spotlight_role.text = "[ %s ]  •  Difficulty %d/3" % [data.role.to_upper(), data.difficulty]

	# Update background splash artwork
	if _bg_splash:
		_bg_splash.texture = data.get_splash_art()

	# Clear previous ability icons
	for child: Node in _abilities_container.get_children():
		child.queue_free()

	# Add Passive Icon Button
	if data.passive:
		var p_btn := _build_ability_button("[P]", data.passive.display_name, data.passive.description, data.passive.icon)
		_abilities_container.add_child(p_btn)

	# Add Q, W, E, R Ability Icon Buttons
	var keys: Array[String] = ["Q", "W", "E", "R"]
	for i: int in range(data.abilities.size()):
		var ab: AbilityData = data.abilities[i]
		if ab:
			var key: String = keys[i] if i < keys.size() else "?"
			var ab_btn := _build_ability_button("[%s]" % key, ab.display_name, ab.description, ab.icon)
			_abilities_container.add_child(ab_btn)

	# Default description to passive
	if data.passive:
		_show_ability_desc("[P] " + data.passive.display_name, data.passive.description)
	elif not data.abilities.is_empty():
		_show_ability_desc("[Q] " + data.abilities[0].display_name, data.abilities[0].description)


func _build_ability_button(key: String, ab_name: String, ab_desc: String, icon_tex: Texture2D) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(34, 34)
	btn.focus_mode = Control.FOCUS_NONE
	btn.tooltip_text = "%s %s\n%s" % [key, ab_name, ab_desc]

	if icon_tex:
		btn.icon = icon_tex
		btn.expand_icon = true

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.16, 0.9)
	style.border_color = COLOR_GOLD_DIM
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.border_color = COLOR_GOLD_BRIGHT
	btn.add_theme_stylebox_override("hover", hover_style)

	btn.mouse_entered.connect(func() -> void:
		_show_ability_desc("%s %s" % [key, ab_name], ab_desc)
		Sfx.play("hover", -18.0)
	)
	btn.pressed.connect(func() -> void:
		_show_ability_desc("%s %s" % [key, ab_name], ab_desc)
	)

	return btn


func _show_ability_desc(title: String, desc: String) -> void:
	if _ability_desc_label:
		_ability_desc_label.text = "%s: %s" % [title, desc]


# =========================================================================
# Live Grid Filtering
# =========================================================================
func _filter_grid() -> void:
	var search_query: String = _search_input.text.strip_edges().to_lower() if _search_input else ""
	for champ_id: StringName in _champ_cards:
		var card: Button = _champ_cards[champ_id]
		var data: ChampionData = ChampionDB.get_champion(champ_id)
		if data == null:
			continue

		var matches_search: bool = search_query.is_empty() or data.display_name.to_lower().contains(search_query)
		var matches_role: bool = _current_role_filter == "ALL" or data.role.to_upper() == _current_role_filter

		card.visible = matches_search and matches_role


func _on_reroll_champion() -> void:
	if ChampionDB.IDS.is_empty():
		return
	var random_id: StringName = ChampionDB.IDS[randi() % ChampionDB.IDS.size()]
	NetworkManager.request_champion(String(random_id))
	_select_preview(random_id)
	Sfx.play("cast", -4.0)
	if _status_label:
		_status_label.text = "Rerolled: %s!" % random_id


# =========================================================================
# Refresh & Player Slots
# =========================================================================
func _refresh() -> void:
	for child: Node in _blue_container.get_children():
		child.queue_free()
	for child: Node in _red_container.get_children():
		child.queue_free()

	var blue_players: Array[Dictionary] = []
	var red_players: Array[Dictionary] = []

	for id: int in NetworkManager.players:
		var info: Dictionary = NetworkManager.players[id]
		if int(info.get("team", 1)) == GameConst.TEAM_BLUE:
			blue_players.append(info)
		else:
			red_players.append(info)

	_blue_count_label.text = "%d/%d" % [blue_players.size(), GameConst.MAX_TEAM_SIZE]
	_red_count_label.text = "%d/%d" % [red_players.size(), GameConst.MAX_TEAM_SIZE]

	for info: Dictionary in blue_players:
		_blue_container.add_child(_build_player_row(info, GameConst.TEAM_BLUE))
	for info: Dictionary in red_players:
		_red_container.add_child(_build_player_row(info, GameConst.TEAM_RED))

	# Update champion card highlights
	var my_champ: String = String(NetworkManager.local_player().get("champion", ChampionDB.default_id()))
	if not ChampionDB.IDS.has(StringName(my_champ)):
		my_champ = String(ChampionDB.default_id())
		NetworkManager.request_champion(my_champ)

	for cid: StringName in _champ_cards:
		var card: Button = _champ_cards[cid]
		var frame: PanelContainer = card.get_child(0).get_child(0) as PanelContainer
		if frame:
			var style: StyleBoxFlat = frame.get_theme_stylebox("panel") as StyleBoxFlat
			if style:
				if String(cid) == my_champ:
					style.border_color = COLOR_HEX_CYAN
					style.set_border_width_all(3)
					card.modulate = Color(1.3, 1.2, 0.9)
				else:
					style.border_color = COLOR_GOLD_DIM
					style.set_border_width_all(2)
					card.modulate = Color(0.85, 0.85, 0.85)

	if _selected_preview_id == &"" or _selected_preview_id == null:
		_select_preview(StringName(my_champ))

	# Lock In Button State
	if NetworkManager.is_host():
		_lock_in_button.text = "START ARAM MATCH"
		_lock_in_button.disabled = NetworkManager.players.is_empty()
	else:
		if _is_locked_in:
			_lock_in_button.text = "LOCKED IN (WAITING FOR HOST)"
			_lock_in_button.disabled = true
		else:
			_lock_in_button.text = "LOCK IN"
			_lock_in_button.disabled = false


func _build_player_row(info: Dictionary, team: int) -> Control:
	var team_color: Color = COLOR_BLUE_TEAM if team == GameConst.TEAM_BLUE else COLOR_RED_TEAM
	var row_panel := UI.panel(UITheme.panel_style(Color(0.04, 0.06, 0.1, 0.92), team_color.lerp(Color.BLACK, 0.4), 4, 1))
	row_panel.custom_minimum_size.y = 48

	var row := UI.hbox(6)
	row_panel.add_child(row)

	var cid: StringName = StringName(info.get("champion", ChampionDB.default_id()))
	var champ: ChampionData = ChampionDB.get_champion(cid)
	if champ and champ.portrait:
		var p_tex := UI.texture_rect(champ.portrait, Vector2(36, 36))
		row.add_child(p_tex)

	var name_box := UI.vbox(1)
	name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_box)

	var is_local: bool = int(info["id"]) == NetworkManager.local_id()
	var name_str: String = String(info["name"]) + (" (You)" if is_local else "")
	var name_color: Color = COLOR_GOLD_BRIGHT if is_local else UITheme.TEXT
	name_box.add_child(UI.label(name_str, 12, name_color, is_local))

	var champ_str: String = champ.display_name if champ else String(cid)
	if bool(info.get("bot", false)):
		champ_str += " [BOT]"
	name_box.add_child(UI.label(champ_str, 10, champ.color if champ else UITheme.TEXT_DIM))

	# Host controls for bot champion selection and kick
	if NetworkManager.is_host():
		if bool(info.get("bot", false)):
			var cycle_btn := UI.button("Change", func() -> void:
				var next_idx: int = (ChampionDB.IDS.find(cid) + 1) % ChampionDB.IDS.size()
				NetworkManager.request_bot_champion(int(info["id"]), String(ChampionDB.IDS[next_idx]))
			, 44)
			cycle_btn.add_theme_font_size_override("font_size", 9)
			row.add_child(cycle_btn)

		if not is_local:
			var kick_btn := UI.button("✕", func() -> void:
				NetworkManager.request_remove(int(info["id"]))
			, 22)
			kick_btn.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
			row.add_child(kick_btn)

	return row_panel


# =========================================================================
# Lock In, Chat & Networking
# =========================================================================
func _on_lock_in_pressed() -> void:
	Sfx.play("announce", -2.0)
	_is_locked_in = true
	if NetworkManager.is_host():
		NetworkManager.start_match()
	else:
		_lock_in_button.text = "LOCKED IN (WAITING FOR HOST)"
		_lock_in_button.disabled = true
		if _status_label:
			_status_label.text = "Locked in! Waiting for host to launch the match..."


func _on_chat(sender: String, team: int, text: String) -> void:
	var color_tag: String = "white"
	if team == GameConst.TEAM_BLUE:
		color_tag = "#64b5f6"
	elif team == GameConst.TEAM_RED:
		color_tag = "#e57373"
	elif sender.is_empty():
		color_tag = "#ffd54f"

	if sender.is_empty():
		_chat_log.append_text("[color=%s][i]%s[/i][/color]\n" % [color_tag, text])
	else:
		_chat_log.append_text("[color=%s][b]%s[/b]:[/color] %s\n" % [color_tag, sender, text])


func _on_send_chat(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	NetworkManager.send_chat(text)
	_chat_input.clear()


func _on_status(text: String, is_error: bool) -> void:
	if _status_label:
		_status_label.text = text
		_status_label.modulate = Color(1.0, 0.35, 0.35) if is_error else COLOR_GOLD_DIM


func _on_leave() -> void:
	NetworkManager.leave()
