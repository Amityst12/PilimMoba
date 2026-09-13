class_name UI
extends RefCounted
## Small factory helpers for building UI in code.


static func label(text: String, size: int = 15, color: Color = UITheme.TEXT, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_override("font", UITheme.font(true))
	return l


static func outlined(l: Label, outline: int = 4) -> Label:
	l.add_theme_constant_override("outline_size", outline)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	return l


static func button(text: String, callback: Callable = Callable(), min_width: float = 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.x = min_width
	b.focus_mode = Control.FOCUS_NONE
	if callback.is_valid():
		b.pressed.connect(callback)
	b.pressed.connect(func() -> void: Sfx.play("click", -6.0))
	b.mouse_entered.connect(func() -> void: Sfx.play("hover", -16.0, 0.02))
	return b


static func vbox(separation: int = 8) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box


static func hbox(separation: int = 8) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box


static func panel(style: StyleBox = null) -> PanelContainer:
	var p := PanelContainer.new()
	if style:
		p.add_theme_stylebox_override("panel", style)
	return p


static func margin(all: int) -> MarginContainer:
	var m := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, all)
	return m


static func spacer(horizontal: bool = true) -> Control:
	var c := Control.new()
	if horizontal:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


static func rich(bbcode: String = "", fit: bool = true) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = fit
	r.scroll_active = not fit
	r.text = bbcode
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func texture_rect(texture: Texture2D, size: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = texture
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


static func full_rect(control: Control) -> Control:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return control


static func champion_portrait(champion_id: String) -> Texture2D:
	var data: ChampionData = ChampionDB.get_champion(StringName(champion_id))
	return data.portrait if data else null
