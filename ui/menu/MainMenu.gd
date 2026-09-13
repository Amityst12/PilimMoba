extends Node3D
## Main menu over a slowly orbiting view of the arena.

@onready var _camera: Camera3D = $MenuCamera
@onready var _ui: CanvasLayer = $UI

var _name_edit: LineEdit
var _address_edit: LineEdit
var _port_edit: LineEdit
var _status: Label
var _modal: Control
var _orbit: float = 0.6


func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = float(NetworkManager.launch_options.get("timescale", 1.0))
	_build_ui()
	NetworkManager.status_changed.connect(_on_status)
	if NetworkManager.pending_message != "":
		_on_status(NetworkManager.pending_message, true)
		NetworkManager.pending_message = ""
	_handle_launch_options.call_deferred()


func _process(delta: float) -> void:
	_orbit += delta * 0.04
	var focus := Vector3(sin(_orbit * 0.7) * 30.0, 0.0, 0.0)
	_camera.global_position = focus + Vector3(sin(_orbit) * 42.0, 30.0, cos(_orbit) * 42.0)
	_camera.look_at(focus, Vector3.UP)


func _build_ui() -> void:
	var root := UI.full_rect(Control.new())
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)
	var shade := UI.full_rect(ColorRect.new())
	shade.color = Color(0.02, 0.03, 0.05, 0.45)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)

	var column := UI.vbox(10)
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	column.offset_left = 60.0
	column.offset_top = -240.0
	column.offset_bottom = 240.0
	column.custom_minimum_size = Vector2(380, 0)
	root.add_child(column)

	var title_box := UI.vbox(2)
	column.add_child(title_box)
	var title_row := UI.hbox(10)
	title_box.add_child(title_row)
	var title := UI.outlined(UI.label("PILIM", 48, UITheme.ACCENT, true), 6)
	title_row.add_child(title)
	var subtitle := UI.outlined(UI.label("MOBA", 26, Color(0.85, 0.9, 1.0), true), 4)
	subtitle.size_flags_vertical = Control.SIZE_SHRINK_END
	title_row.add_child(subtitle)
	title_box.add_child(UI.outlined(UI.label("Top-down 5v5 arena battles  -  v%s" % GameConst.GAME_VERSION, 13, UITheme.TEXT_DIM)))

	var panel := UI.panel(UITheme.panel_style(UITheme.BG, UITheme.BORDER, 8))
	column.add_child(panel)
	var box := UI.vbox(10)
	panel.add_child(box)

	box.add_child(UI.label("Champion name", 13, UITheme.TEXT_DIM))
	_name_edit = LineEdit.new()
	_name_edit.text = Settings.player_name
	_name_edit.max_length = 16
	_name_edit.placeholder_text = "Your name"
	box.add_child(_name_edit)

	var practice := UI.button("PRACTICE VS BOTS", _on_practice)
	practice.custom_minimum_size.y = 44
	practice.add_theme_font_size_override("font_size", 17)
	box.add_child(practice)
	box.add_child(HSeparator.new())

	var host_row := UI.hbox(8)
	box.add_child(host_row)
	var host_button := UI.button("HOST GAME", _on_host)
	host_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host_row.add_child(host_button)
	host_row.add_child(UI.label("Port", 13, UITheme.TEXT_DIM))
	_port_edit = LineEdit.new()
	_port_edit.text = str(Settings.port)
	_port_edit.custom_minimum_size.x = 70
	host_row.add_child(_port_edit)

	var join_row := UI.hbox(8)
	box.add_child(join_row)
	_address_edit = LineEdit.new()
	_address_edit.text = Settings.last_address
	_address_edit.placeholder_text = "Host IP address"
	_address_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_address_edit.text_submitted.connect(func(_t: String) -> void: _on_join())
	join_row.add_child(_address_edit)
	var join_button := UI.button("JOIN", _on_join, 90)
	join_row.add_child(join_button)

	box.add_child(HSeparator.new())
	var bottom_row := UI.hbox(8)
	box.add_child(bottom_row)
	var settings_button := UI.button("Settings", _on_settings)
	settings_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(settings_button)
	var quit_button := UI.button("Quit", func() -> void: get_tree().quit())
	quit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(quit_button)

	_status = UI.outlined(UI.label("", 14, UITheme.TEXT_DIM))
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size.x = 380
	column.add_child(_status)

	var controls := UI.rich("[color=#c9b27a][b]CONTROLS[/b][/color]\n"
		+ "[color=#e8e4d8]Right click[/color]  move / attack\n"
		+ "[color=#e8e4d8]Q W E R[/color]  hold to aim, release to cast\n"
		+ "[color=#e8e4d8]Ctrl + Q/W/E/R[/color]  rank up ability\n"
		+ "[color=#e8e4d8]G / V / Alt+Click[/color]  smart pings\n"
		+ "[color=#e8e4d8]A[/color] attack-move   [color=#e8e4d8]S[/color] stop   [color=#e8e4d8]B[/color] recall\n"
		+ "[color=#e8e4d8]P[/color] shop   [color=#e8e4d8]Tab[/color] scoreboard   [color=#e8e4d8]Y[/color] lock camera\n"
		+ "[color=#e8e4d8]Space[/color] center camera")
	controls.add_theme_font_size_override("normal_font_size", 12)
	controls.add_theme_font_size_override("bold_font_size", 13)
	var controls_panel := UI.panel(UITheme.panel_style(Color(0.03, 0.04, 0.06, 0.85), UITheme.BORDER_DIM, 8))
	controls_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	controls_panel.offset_left = -330.0
	controls_panel.offset_top = -205.0
	controls_panel.offset_right = -20.0
	controls_panel.offset_bottom = -20.0
	controls_panel.custom_minimum_size = Vector2(310, 0)
	controls_panel.add_child(controls)
	root.add_child(controls_panel)


func _save_name() -> String:
	var player_name: String = NetworkManager.sanitize_text(_name_edit.text, 16)
	if player_name.is_empty():
		player_name = Settings.player_name
	Settings.player_name = player_name
	Settings.save_settings()
	return player_name


func _port() -> int:
	var port: int = _port_edit.text.to_int()
	if port < 1024 or port > 65535:
		port = GameConst.DEFAULT_PORT
	Settings.port = port
	return port


func _on_practice() -> void:
	NetworkManager.start_practice(_save_name())


func _on_host() -> void:
	var player_name: String = _save_name()
	NetworkManager.host(_port(), player_name)


func _on_join() -> void:
	var player_name: String = _save_name()
	Settings.last_address = _address_edit.text.strip_edges()
	Settings.save_settings()
	NetworkManager.join(Settings.last_address, _port(), player_name)


func _on_settings() -> void:
	if is_instance_valid(_modal):
		return
	var panel := SettingsPanel.new()
	_modal = panel
	var center := UI.full_rect(CenterContainer.new())
	_ui.add_child(center)
	center.add_child(panel)
	panel.closed.connect(center.queue_free)


func _on_status(text: String, is_error: bool) -> void:
	if _status:
		_status.text = text
		_status.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4) if is_error else Color(0.7, 0.9, 1.0))


func _handle_launch_options() -> void:
	if NetworkManager.launch_consumed:
		return
	var options: Dictionary = NetworkManager.launch_options
	var player_name: String = String(options.get("name", Settings.player_name))
	var port: int = int(options.get("port", GameConst.DEFAULT_PORT))
	if options.has("champion"):
		Settings.last_champion = String(options["champion"])
	if options.has("practice"):
		NetworkManager.launch_consumed = true
		NetworkManager.start_practice(player_name)
	elif options.has("settings"):
		_on_settings()
	elif options.has("host") or options.has("dedicated"):
		NetworkManager.launch_consumed = true
		NetworkManager.host(port, player_name, options.has("dedicated"))
	elif options.has("join"):
		NetworkManager.launch_consumed = true
		NetworkManager.join(String(options["join"]), port, player_name)
