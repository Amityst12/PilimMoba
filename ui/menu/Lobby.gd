class_name Lobby
extends Node3D
## Pre-match lobby: team assignment, champion select, bot management and chat.

@onready var _camera: Camera3D = $LobbyCamera
@onready var _ui: CanvasLayer = $UI

var _blue_container: VBoxContainer
var _red_container: VBoxContainer
var _blue_count_label: Label
var _red_count_label: Label
var _start_button: Button
var _status_label: Label
var _chat_log: RichTextLabel
var _chat_input: LineEdit
var _champ_cards: Dictionary = {}
var _preview_name: Label
var _preview_role: Label
var _preview_lore: Label
var _preview_stats: Label
var _preview_abilities: VBoxContainer
var _selected_preview_id: StringName = &""
var _orbit: float = 1.2


func _ready() -> void:
	get_tree().paused = false
	_build_ui()
	NetworkManager.lobby_changed.connect(_refresh)
	NetworkManager.chat_received.connect(_on_chat)
	NetworkManager.status_changed.connect(_on_status)
	_refresh()


func _process(delta: float) -> void:
	_orbit += delta * 0.03
	var focus := Vector3(0.0, 0.0, 0.0)
	_camera.global_position = focus + Vector3(sin(_orbit) * 35.0, 24.0, cos(_orbit) * 35.0)
	_camera.look_at(focus, Vector3.UP)


func _build_ui() -> void:
	var root := UI.full_rect(Control.new())
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)

	var shade := UI.full_rect(ColorRect.new())
	shade.color = Color(0.02, 0.03, 0.05, 0.5)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)

	var main_vbox := UI.vbox(10)
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.offset_left = 30
	main_vbox.offset_top = 20
	main_vbox.offset_right = -30
	main_vbox.offset_bottom = -20
	root.add_child(main_vbox)

	# --- Header Bar ---
	var header := UI.hbox(16)
	main_vbox.add_child(header)

	var title := UI.outlined(UI.label("PILIM ARENA", 28, UITheme.ACCENT, true), 4)
	header.add_child(title)

	var mode_str := "Practice Mode (Offline)"
	if NetworkManager.mode == NetworkManager.Mode.HOST:
		var ips: PackedStringArray = NetworkManager.local_ipv4_addresses()
		var ip_str: String = ips[0] if not ips.is_empty() else "127.0.0.1"
		mode_str = "Hosting Online  -  IP: %s : %d" % [ip_str, NetworkManager.host_port]
	elif NetworkManager.mode == NetworkManager.Mode.CLIENT:
		mode_str = "Connected as Client"
	var mode_label := UI.outlined(UI.label(mode_str, 15, UITheme.TEXT_DIM), 3)
	header.add_child(mode_label)

	header.add_child(UI.spacer(true))

	var leave_btn := UI.button("Leave Lobby", _on_leave, 110)
	header.add_child(leave_btn)

	main_vbox.add_child(HSeparator.new())

	# --- Main Columns (Blue Team | Champion Select & Chat | Red Team) ---
	var body := UI.hbox(14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(body)

	# 1. Left: Blue Team Panel
	var blue_panel := UI.panel(UITheme.panel_style(Color(0.04, 0.08, 0.14, 0.92), Color(0.2, 0.5, 0.9, 0.8), 6, 2))
	blue_panel.custom_minimum_size = Vector2(280, 0)
	body.add_child(blue_panel)

	var blue_box := UI.vbox(8)
	blue_panel.add_child(blue_box)

	var blue_hdr := UI.hbox(8)
	blue_box.add_child(blue_hdr)
	blue_hdr.add_child(UI.label("ORDER (BLUE)", 18, Color(0.4, 0.7, 1.0), true))
	blue_hdr.add_child(UI.spacer(true))
	_blue_count_label = UI.label("0/5", 14, UITheme.TEXT_DIM)
	blue_hdr.add_child(_blue_count_label)

	blue_box.add_child(HSeparator.new())

	var blue_scroll := ScrollContainer.new()
	blue_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	blue_box.add_child(blue_scroll)
	_blue_container = UI.vbox(6)
	_blue_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	blue_scroll.add_child(_blue_container)

	var blue_btn_row := UI.hbox(6)
	blue_box.add_child(blue_btn_row)
	var join_blue_btn := UI.button("Switch to Blue", func() -> void: NetworkManager.request_team(GameConst.TEAM_BLUE))
	join_blue_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	blue_btn_row.add_child(join_blue_btn)
	if NetworkManager.is_host():
		var add_bot_blue := UI.button("+ Bot", func() -> void: NetworkManager.request_add_bot(GameConst.TEAM_BLUE), 60)
		blue_btn_row.add_child(add_bot_blue)

	# 2. Center: Champion Selection & Details + Chat
	var center_box := UI.vbox(10)
	center_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(center_box)

	# Champion Select Bar
	var select_panel := UI.panel(UITheme.panel_style(UITheme.BG, UITheme.BORDER, 6))
	select_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_box.add_child(select_panel)

	var select_vbox := UI.vbox(8)
	select_panel.add_child(select_vbox)

	var select_title := UI.label("CHOOSE YOUR CHAMPION", 16, UITheme.ACCENT, true)
	select_vbox.add_child(select_title)

	var cards_row := UI.hbox(10)
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	select_vbox.add_child(cards_row)

	for champ_id: StringName in ChampionDB.IDS:
		var champ_data: ChampionData = ChampionDB.get_champion(champ_id)
		if champ_data == null:
			continue
		var card := _build_champ_card(champ_data)
		cards_row.add_child(card)
		_champ_cards[champ_id] = card

	select_vbox.add_child(HSeparator.new())

	# Champion Details / Abilities Preview
	var preview_row := UI.hbox(16)
	preview_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	select_vbox.add_child(preview_row)

	var preview_left := UI.vbox(4)
	preview_left.custom_minimum_size = Vector2(240, 0)
	preview_row.add_child(preview_left)

	_preview_name = UI.label("", 20, UITheme.TEXT, true)
	preview_left.add_child(_preview_name)
	_preview_role = UI.label("", 14, UITheme.ACCENT)
	preview_left.add_child(_preview_role)
	_preview_lore = UI.label("", 12, UITheme.TEXT_DIM)
	_preview_lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_left.add_child(_preview_lore)
	_preview_stats = UI.label("", 12, Color(0.7, 0.85, 0.7))
	preview_left.add_child(_preview_stats)

	var preview_right := UI.vbox(4)
	preview_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_row.add_child(preview_right)
	preview_right.add_child(UI.label("ABILITIES", 13, UITheme.TEXT_DIM, true))

	_preview_abilities = UI.vbox(4)
	preview_right.add_child(_preview_abilities)

	# Chat Box
	var chat_panel := UI.panel(UITheme.panel_style(Color(0.04, 0.05, 0.07, 0.95), UITheme.BORDER_DIM, 4))
	chat_panel.custom_minimum_size = Vector2(0, 140)
	center_box.add_child(chat_panel)

	var chat_vbox := UI.vbox(6)
	chat_panel.add_child(chat_vbox)

	_chat_log = RichTextLabel.new()
	_chat_log.bbcode_enabled = true
	_chat_log.scroll_following = true
	_chat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chat_log.focus_mode = Control.FOCUS_NONE
	chat_vbox.add_child(_chat_log)

	var input_row := UI.hbox(6)
	chat_vbox.add_child(input_row)

	_chat_input = LineEdit.new()
	_chat_input.placeholder_text = "Type chat message and press Enter..."
	_chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_input.text_submitted.connect(_on_send_chat)
	input_row.add_child(_chat_input)

	var send_btn := UI.button("Send", func() -> void: _on_send_chat(_chat_input.text), 70)
	input_row.add_child(send_btn)

	# 3. Right: Red Team Panel
	var red_panel := UI.panel(UITheme.panel_style(Color(0.14, 0.05, 0.05, 0.92), Color(0.9, 0.25, 0.25, 0.8), 6, 2))
	red_panel.custom_minimum_size = Vector2(280, 0)
	body.add_child(red_panel)

	var red_box := UI.vbox(8)
	red_panel.add_child(red_box)

	var red_hdr := UI.hbox(8)
	red_box.add_child(red_hdr)
	red_hdr.add_child(UI.label("CHAOS (RED)", 18, Color(1.0, 0.45, 0.45), true))
	red_hdr.add_child(UI.spacer(true))
	_red_count_label = UI.label("0/5", 14, UITheme.TEXT_DIM)
	red_hdr.add_child(_red_count_label)

	red_box.add_child(HSeparator.new())

	var red_scroll := ScrollContainer.new()
	red_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	red_box.add_child(red_scroll)
	_red_container = UI.vbox(6)
	_red_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	red_scroll.add_child(_red_container)

	var red_btn_row := UI.hbox(6)
	red_box.add_child(red_btn_row)
	var join_red_btn := UI.button("Switch to Red", func() -> void: NetworkManager.request_team(GameConst.TEAM_RED))
	join_red_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	red_btn_row.add_child(join_red_btn)
	if NetworkManager.is_host():
		var add_bot_red := UI.button("+ Bot", func() -> void: NetworkManager.request_add_bot(GameConst.TEAM_RED), 60)
		red_btn_row.add_child(add_bot_red)

	# --- Bottom Action Bar ---
	main_vbox.add_child(HSeparator.new())
	var footer := UI.hbox(16)
	main_vbox.add_child(footer)

	_status_label = UI.label("", 14, UITheme.TEXT_DIM)
	footer.add_child(_status_label)

	footer.add_child(UI.spacer(true))

	_start_button = UI.button("START MATCH", _on_start_match, 220)
	_start_button.custom_minimum_size.y = 44
	_start_button.add_theme_font_size_override("font_size", 18)
	_start_button.add_theme_color_override("font_color", UITheme.ACCENT)
	footer.add_child(_start_button)


func _build_champ_card(data: ChampionData) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(170, 74)
	btn.focus_mode = Control.FOCUS_NONE

	var hbox := UI.hbox(8)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 6
	hbox.offset_right = -6
	hbox.offset_top = 4
	hbox.offset_bottom = -4
	btn.add_child(hbox)

	if data.portrait:
		var icon_rect := UI.texture_rect(data.portrait, Vector2(50, 50))
		hbox.add_child(icon_rect)

	var text_box := UI.vbox(2)
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(text_box)

	var name_lbl := UI.label(data.display_name, 15, UITheme.TEXT, true)
	text_box.add_child(name_lbl)
	var role_lbl := UI.label(data.role, 12, data.color)
	text_box.add_child(role_lbl)

	btn.pressed.connect(func() -> void:
		NetworkManager.request_champion(String(data.id))
		_select_preview(data.id)
	)
	return btn


func _select_preview(champion_id: StringName) -> void:
	_selected_preview_id = champion_id
	var data: ChampionData = ChampionDB.get_champion(champion_id)
	if data == null:
		return
	_preview_name.text = "%s - %s" % [data.display_name, data.title]
	_preview_role.text = "Role: %s  |  Difficulty: %d/3" % [data.role, data.difficulty]
	_preview_lore.text = data.lore
	_preview_stats.text = "HP: %d  |  Mana: %d  |  AD: %d  |  Armor: %d  |  Speed: %.1f" % [
		int(data.max_health), int(data.max_mana), int(data.attack_damage), int(data.armor), data.move_speed
	]

	for child: Node in _preview_abilities.get_children():
		child.queue_free()

	if data.passive:
		var pass_row := UI.hbox(6)
		pass_row.add_child(UI.label("[P] %s:" % data.passive.display_name, 12, UITheme.ACCENT, true))
		pass_row.add_child(UI.label(data.passive.description, 11, UITheme.TEXT_DIM))
		_preview_abilities.add_child(pass_row)

	var keys: Array[String] = ["Q", "W", "E", "R"]
	for i: int in range(data.abilities.size()):
		var ab: AbilityData = data.abilities[i]
		if ab:
			var ab_row := UI.hbox(6)
			var key_lbl := UI.label("[%s] %s:" % [keys[i] if i < keys.size() else "?", ab.display_name], 12, ab.color, true)
			ab_row.add_child(key_lbl)
			var desc_lbl := UI.label(ab.description, 11, UITheme.TEXT_DIM)
			ab_row.add_child(desc_lbl)
			_preview_abilities.add_child(ab_row)


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
		_blue_container.add_child(_build_player_row(info))
	for info: Dictionary in red_players:
		_red_container.add_child(_build_player_row(info))

	# Update champion card highlights
	var my_champ: String = String(NetworkManager.local_player().get("champion", ChampionDB.default_id()))
	for cid: StringName in _champ_cards:
		var card: Button = _champ_cards[cid]
		if String(cid) == my_champ:
			card.modulate = Color(1.3, 1.2, 0.8)
		else:
			card.modulate = Color(0.85, 0.85, 0.85)

	if _selected_preview_id == &"" or _selected_preview_id == null:
		_select_preview(StringName(my_champ))

	# Start button state
	if NetworkManager.is_host():
		_start_button.visible = true
		_start_button.text = "START MATCH"
		_start_button.disabled = NetworkManager.players.is_empty()
	else:
		_start_button.visible = true
		_start_button.text = "WAITING FOR HOST..."
		_start_button.disabled = true


func _build_player_row(info: Dictionary) -> Control:
	var row_panel := UI.panel(UITheme.panel_style(Color(0.06, 0.08, 0.11, 0.9), UITheme.BORDER_DIM, 4))
	var row := UI.hbox(8)
	row_panel.add_child(row)

	var cid: StringName = StringName(info.get("champion", ChampionDB.default_id()))
	var champ: ChampionData = ChampionDB.get_champion(cid)
	if champ and champ.portrait:
		row.add_child(UI.texture_rect(champ.portrait, Vector2(36, 36)))

	var name_box := UI.vbox(1)
	name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_box)

	var is_local: bool = int(info["id"]) == NetworkManager.local_id()
	var name_str: String = String(info["name"]) + (" (You)" if is_local else "")
	var name_color: Color = UITheme.ACCENT if is_local else UITheme.TEXT
	name_box.add_child(UI.label(name_str, 13, name_color, is_local))

	var champ_str: String = champ.display_name if champ else String(cid)
	if bool(info.get("bot", false)):
		champ_str += " [BOT]"
	name_box.add_child(UI.label(champ_str, 11, champ.color if champ else UITheme.TEXT_DIM))

	# Host controls for bot champion selection and kick
	if NetworkManager.is_host():
		if bool(info.get("bot", false)):
			var cycle_btn := UI.button("Change", func() -> void:
				var next_idx: int = (ChampionDB.IDS.find(cid) + 1) % ChampionDB.IDS.size()
				NetworkManager.request_bot_champion(int(info["id"]), String(ChampionDB.IDS[next_idx]))
			, 50)
			cycle_btn.add_theme_font_size_override("font_size", 10)
			row.add_child(cycle_btn)

		if not is_local:
			var kick_btn := UI.button("X", func() -> void:
				NetworkManager.request_remove(int(info["id"]))
			, 24)
			kick_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			row.add_child(kick_btn)

	return row_panel


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
	_status_label.text = text
	_status_label.modulate = Color(1.0, 0.35, 0.35) if is_error else UITheme.TEXT_DIM


func _on_leave() -> void:
	NetworkManager.leave()


func _on_start_match() -> void:
	if NetworkManager.is_host():
		NetworkManager.start_match()
