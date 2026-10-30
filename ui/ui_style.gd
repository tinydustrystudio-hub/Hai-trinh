class_name UiStyle
extends RefCounted
## Kiểu chữ và nút dùng chung cho giao diện trận (GDD mục 7.1): nút chính màu cam cứu hộ,
## nút tối thiểu 120 px ở độ phân giải gốc, chữ dễ đọc trên điện thoại.

const PRIMARY: Color = Color(1.0, 0.45, 0.1)
const PRIMARY_PRESSED: Color = Color(0.85, 0.35, 0.05)
const PANEL: Color = Color(0.02, 0.12, 0.18, 0.82)
const TEXT: Color = Color(1, 1, 1)
const TEXT_SIZE: int = 40
const TITLE_SIZE: int = 96
const BUTTON_TEXT_SIZE: int = 48
const MIN_BUTTON: Vector2 = Vector2(120, 120)
const MARGIN: int = 32


static func label(size: int = TEXT_SIZE) -> Label:
	var result: Label = Label.new()
	result.add_theme_font_size_override(&"font_size", size)
	result.add_theme_color_override(&"font_color", TEXT)
	result.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.8))
	result.add_theme_constant_override(&"outline_size", 8)
	return result


static func primary_button(text_key: StringName, min_size: Vector2 = Vector2(360, 140)) -> Button:
	var button: Button = Button.new()
	button.text = text_key
	button.custom_minimum_size = Vector2(maxf(min_size.x, MIN_BUTTON.x), maxf(min_size.y, MIN_BUTTON.y))
	button.add_theme_font_size_override(&"font_size", BUTTON_TEXT_SIZE)
	button.add_theme_color_override(&"font_color", TEXT)
	button.add_theme_color_override(&"font_pressed_color", TEXT)
	button.add_theme_color_override(&"font_hover_color", TEXT)
	button.add_theme_stylebox_override(&"normal", _box(PRIMARY))
	button.add_theme_stylebox_override(&"hover", _box(PRIMARY.lightened(0.1)))
	button.add_theme_stylebox_override(&"pressed", _box(PRIMARY_PRESSED))
	button.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	return button


static func panel_box() -> StyleBoxFlat:
	return _box(PANEL)


static func _box(color: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(20)
	box.set_content_margin_all(24)
	return box
