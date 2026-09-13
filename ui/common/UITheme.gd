class_name UITheme
extends RefCounted
## Builds the global UI theme in code (dark slate panels with bronze accents).

const BG: Color = Color(0.055, 0.07, 0.095, 0.94)
const BG_LIGHT: Color = Color(0.1, 0.125, 0.165, 0.95)
const BORDER: Color = Color(0.72, 0.6, 0.36, 0.9)
const BORDER_DIM: Color = Color(0.3, 0.33, 0.4, 0.9)
const TEXT: Color = Color(0.92, 0.9, 0.85)
const TEXT_DIM: Color = Color(0.62, 0.65, 0.7)
const ACCENT: Color = Color(0.95, 0.78, 0.4)

static var _font: SystemFont
static var _font_bold: SystemFont


static func font(bold: bool = false) -> Font:
	if _font == null:
		_font = SystemFont.new()
		_font.font_names = PackedStringArray(["Bahnschrift", "Segoe UI", "Noto Sans", "Arial"])
		_font.font_weight = 400
		_font_bold = SystemFont.new()
		_font_bold.font_names = PackedStringArray(["Bahnschrift", "Segoe UI", "Noto Sans", "Arial"])
		_font_bold.font_weight = 700
	return _font_bold if bold else _font


static func panel_style(bg: Color = BG, border: Color = BORDER_DIM, radius: int = 6, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 4
	return style


static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font = font()
	theme.default_font_size = 15

	theme.set_stylebox("panel", "PanelContainer", panel_style())
	theme.set_stylebox("panel", "Panel", panel_style())

	var button_normal := panel_style(Color(0.13, 0.15, 0.2, 0.95), BORDER_DIM, 5)
	button_normal.content_margin_top = 7
	button_normal.content_margin_bottom = 7
	button_normal.content_margin_left = 14
	button_normal.content_margin_right = 14
	button_normal.shadow_size = 0
	var button_hover := button_normal.duplicate() as StyleBoxFlat
	button_hover.bg_color = Color(0.2, 0.22, 0.28, 0.98)
	button_hover.border_color = BORDER
	var button_pressed := button_normal.duplicate() as StyleBoxFlat
	button_pressed.bg_color = Color(0.3, 0.25, 0.14, 1.0)
	button_pressed.border_color = ACCENT
	var button_disabled := button_normal.duplicate() as StyleBoxFlat
	button_disabled.bg_color = Color(0.1, 0.11, 0.13, 0.8)
	button_disabled.border_color = Color(0.2, 0.2, 0.22, 0.8)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = Color(ACCENT, 0.6)
	focus.set_border_width_all(1)
	focus.set_corner_radius_all(5)
	theme.set_stylebox("normal", "Button", button_normal)
	theme.set_stylebox("hover", "Button", button_hover)
	theme.set_stylebox("pressed", "Button", button_pressed)
	theme.set_stylebox("disabled", "Button", button_disabled)
	theme.set_stylebox("focus", "Button", focus)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color(1.0, 0.95, 0.8))
	theme.set_color("font_pressed_color", "Button", ACCENT)
	theme.set_color("font_disabled_color", "Button", Color(0.45, 0.45, 0.48))
	theme.set_font("font", "Button", font(true))

	var edit := panel_style(Color(0.04, 0.05, 0.07, 0.95), BORDER_DIM, 4)
	edit.shadow_size = 0
	var edit_focus := edit.duplicate() as StyleBoxFlat
	edit_focus.border_color = BORDER
	theme.set_stylebox("normal", "LineEdit", edit)
	theme.set_stylebox("focus", "LineEdit", edit_focus)
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", Color(0.5, 0.52, 0.56))
	theme.set_color("caret_color", "LineEdit", ACCENT)

	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.9))
	theme.set_color("default_color", "RichTextLabel", TEXT)
	theme.set_font("bold_font", "RichTextLabel", font(true))
	theme.set_font_size("normal_font_size", "RichTextLabel", 14)
	theme.set_font_size("bold_font_size", "RichTextLabel", 14)

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.03, 0.035, 0.05, 0.9)
	bar_bg.set_corner_radius_all(3)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.3, 0.7, 0.35)
	bar_fill.set_corner_radius_all(3)
	theme.set_stylebox("background", "ProgressBar", bar_bg)
	theme.set_stylebox("fill", "ProgressBar", bar_fill)

	var slider := StyleBoxFlat.new()
	slider.bg_color = Color(0.2, 0.22, 0.28)
	slider.set_corner_radius_all(3)
	slider.content_margin_top = 3
	slider.content_margin_bottom = 3
	theme.set_stylebox("slider", "HSlider", slider)
	var grabber_area := slider.duplicate() as StyleBoxFlat
	grabber_area.bg_color = BORDER
	theme.set_stylebox("grabber_area", "HSlider", grabber_area)
	theme.set_stylebox("grabber_area_highlight", "HSlider", grabber_area)

	var tooltip := panel_style(Color(0.04, 0.05, 0.07, 0.97), BORDER, 4)
	theme.set_stylebox("panel", "TooltipPanel", tooltip)
	theme.set_color("font_color", "TooltipLabel", TEXT)

	var separator := StyleBoxLine.new()
	separator.color = Color(BORDER, 0.35)
	separator.thickness = 1
	theme.set_stylebox("separator", "HSeparator", separator)

	var scroll := StyleBoxFlat.new()
	scroll.bg_color = Color(0.3, 0.32, 0.38, 0.6)
	scroll.set_corner_radius_all(3)
	theme.set_stylebox("grabber", "VScrollBar", scroll)
	theme.set_stylebox("scroll", "VScrollBar", StyleBoxEmpty.new())
	return theme
