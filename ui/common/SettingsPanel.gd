class_name SettingsPanel
extends PanelContainer
## Settings window shared by the main menu and the in-game menu.

signal closed


func _ready() -> void:
	custom_minimum_size = Vector2(460, 0)
	add_theme_stylebox_override("panel", UITheme.panel_style(UITheme.BG, UITheme.BORDER, 8))
	var box := UI.vbox(10)
	add_child(box)
	box.add_child(UI.label("SETTINGS", 22, UITheme.ACCENT, true))
	box.add_child(HSeparator.new())

	# --- Video / Display (Strict 16:9) ---
	box.add_child(UI.label("DISPLAY (16:9)", 13, UITheme.ACCENT, true))
	box.add_child(_dropdown_row("Display Mode", Settings.WINDOW_MODES, Settings.window_mode_idx, func(idx: int) -> void:
		Settings.window_mode_idx = idx
		Settings.apply()
		Settings.save_settings()))

	box.add_child(_dropdown_row("Resolution", Settings.RESOLUTION_LABELS_16_9, Settings.resolution_idx, func(idx: int) -> void:
		Settings.resolution_idx = idx
		Settings.apply()
		Settings.save_settings()))

	box.add_child(_toggle_row("V-Sync", Settings.vsync, func(v: bool) -> void:
		Settings.vsync = v
		Settings.apply()
		Settings.save_settings()))
	box.add_child(_toggle_row("Show FPS / Ping", Settings.show_fps, func(v: bool) -> void:
		Settings.show_fps = v
		Settings.save_settings()))

	box.add_child(HSeparator.new())

	# --- Audio ---
	box.add_child(UI.label("AUDIO", 13, UITheme.ACCENT, true))
	box.add_child(_slider_row("Master Volume", Settings.master_volume, func(v: float) -> void:
		Settings.master_volume = v
		Settings.apply()))
	box.add_child(_slider_row("Effects Volume", Settings.sfx_volume, func(v: float) -> void:
		Settings.sfx_volume = v))

	box.add_child(HSeparator.new())

	# --- Gameplay ---
	box.add_child(UI.label("GAMEPLAY", 13, UITheme.ACCENT, true))
	box.add_child(_toggle_row("Camera locked to champion (Y)", Settings.camera_locked, func(v: bool) -> void:
		Settings.camera_locked = v
		if Game.current and Game.current.camera_rig:
			Game.current.camera_rig.locked = v))
	box.add_child(_toggle_row("Screen shake", Settings.screen_shake, func(v: bool) -> void:
		Settings.screen_shake = v))

	box.add_child(HSeparator.new())

	# In-game exit button if inside a match
	if Game.current != null and is_instance_valid(Game.current):
		var leave_btn := UI.button("Leave Game (חזור לתפריט הראשי)", func() -> void:
			closed.emit()
			queue_free()
			NetworkManager.leave("Left match."))
		leave_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
		box.add_child(leave_btn)

	var close := UI.button("Close", func() -> void:
		Settings.save_settings()
		closed.emit()
		queue_free())
	box.add_child(close)


func _dropdown_row(text: String, items: Array[String], selected_idx: int, on_select: Callable) -> Control:
	var row := UI.hbox(12)
	var l := UI.label(text)
	l.custom_minimum_size.x = 160
	row.add_child(l)
	var opt := OptionButton.new()
	for i in range(items.size()):
		opt.add_item(items[i], i)
	opt.selected = clampi(selected_idx, 0, items.size() - 1)
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.focus_mode = Control.FOCUS_NONE
	opt.item_selected.connect(on_select)
	row.add_child(opt)
	return row


func _slider_row(text: String, value: float, on_change: Callable) -> Control:
	var row := UI.hbox(12)
	var l := UI.label(text)
	l.custom_minimum_size.x = 160
	row.add_child(l)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_NONE
	slider.value_changed.connect(on_change)
	row.add_child(slider)
	return row


func _toggle_row(text: String, value: bool, on_change: Callable) -> Control:
	var check := CheckButton.new()
	check.text = text
	check.button_pressed = value
	check.focus_mode = Control.FOCUS_NONE
	check.toggled.connect(on_change)
	return check
