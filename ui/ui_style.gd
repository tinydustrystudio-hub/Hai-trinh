class_name UiStyle
extends RefCounted
## Kiểu chữ và nút dùng chung cho giao diện trận (GDD mục 7.1): nút chính màu cam cứu hộ,
## nút tối thiểu 120 px ở độ phân giải gốc, chữ dễ đọc trên điện thoại.

## Bảng màu Liên Minh Mũi Neo (concept pack mục A).
const SEA_BLUE: Color = Color("1F5F8B")
const IVORY: Color = Color("EDE6D6")
const RESCUE_ORANGE: Color = Color("FF7A1A")
const GRAPHITE: Color = Color("3A4048")
## Vàng của đồng Tiền Vàng.
const GOLD: Color = Color(1.0, 0.8, 0.28)
const GOLD_DARK: Color = Color(0.78, 0.52, 0.1)

const PRIMARY: Color = RESCUE_ORANGE
const PRIMARY_PRESSED: Color = Color(0.82, 0.4, 0.06)
## Mép dưới dày của nút (nổi khối), tối hơn màu nút.
const BUTTON_LIP: float = 7.0
const PANEL: Color = Color(0.03, 0.13, 0.2, 0.9)
## Nút bị khóa: xám (GDD mục 7.1).
const DISABLED: Color = Color(0.42, 0.44, 0.47)
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
	return _button(text_key, min_size, PRIMARY, PRIMARY_PRESSED)


## Nút phụ (Hủy, Quay lại): xanh than, ít nổi hơn nút chính cam.
static func secondary_button(text_key: StringName, min_size: Vector2 = Vector2(240, 140)) -> Button:
	return _button(text_key, min_size, GRAPHITE.lightened(0.1), GRAPHITE.darkened(0.1))


static func _button(text_key: StringName, min_size: Vector2, color: Color, pressed: Color) -> Button:
	var button: Button = Button.new()
	button.text = text_key
	button.custom_minimum_size = Vector2(maxf(min_size.x, MIN_BUTTON.x), maxf(min_size.y, MIN_BUTTON.y))
	# Chữ dài thì xuống dòng trong nút, không làm nút nở ra đè lên nút bên cạnh.
	button.autowrap_mode = TextServer.AUTOWRAP_WORD
	button.add_theme_font_size_override(&"font_size", BUTTON_TEXT_SIZE)
	button.add_theme_color_override(&"font_color", TEXT)
	button.add_theme_color_override(&"font_pressed_color", TEXT)
	button.add_theme_color_override(&"font_hover_color", TEXT)
	button.add_theme_color_override(&"font_disabled_color", Color(1, 1, 1, 0.85))
	button.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.35))
	button.add_theme_constant_override(&"outline_size", 6)
	button.add_theme_stylebox_override(&"normal", button_box(color, false))
	button.add_theme_stylebox_override(&"hover", button_box(color.lightened(0.1), false))
	button.add_theme_stylebox_override(&"pressed", button_box(pressed, true))
	button.add_theme_stylebox_override(&"disabled", button_box(DISABLED, false))
	button.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	button.pressed.connect(func() -> void: Events.ui_clicked.emit())
	return button


## Nút nổi khối: viền ngà mảnh quanh, mép dưới dày tối hơn; bấm xuống thì mép dưới mỏng đi và nội dung hạ xuống.
static func button_box(color: Color, pushed: bool) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(24)
	box.set_border_width_all(3)
	box.border_color = IVORY.darkened(0.05) if color != DISABLED else Color(0.6, 0.62, 0.65)
	box.border_width_bottom = int(BUTTON_LIP * (0.4 if pushed else 1.0))
	box.set_content_margin_all(20)
	box.content_margin_top = 20 + (4 if pushed else 0)
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 0 if pushed else 8
	box.shadow_offset = Vector2(0, 4)
	return box


## Khung bảng: xanh biển rất đậm, viền ngà, đổ bóng nhẹ.
static func panel_box() -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = PANEL
	box.set_corner_radius_all(28)
	box.set_border_width_all(3)
	box.border_color = IVORY.darkened(0.15)
	box.set_content_margin_all(28)
	box.shadow_color = Color(0, 0, 0, 0.4)
	box.shadow_size = 14
	return box
