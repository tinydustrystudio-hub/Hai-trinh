class_name IconButton
extends Button
## Nút tròn chỉ có biểu tượng vẽ bằng code (dấu tích, dấu nhân): gọn, hiện đại, đặt cạnh vật thể thay cho nút chữ.
## Kích thước tối thiểu 120 px (GDD mục 7.1). Dùng cho xác nhận xây và hủy ngay cạnh bệ.

enum Kind { CHECK, CROSS }

const SIZE: float = 120.0

var kind: Kind = Kind.CHECK

var _glyph: Control


func setup(icon: Kind, color: Color, pressed_color: Color) -> void:
	kind = icon
	custom_minimum_size = Vector2(SIZE, SIZE)
	size = Vector2(SIZE, SIZE)
	focus_mode = Control.FOCUS_NONE
	for state: StringName in [&"normal", &"hover"]:
		add_theme_stylebox_override(state, _circle(color, false))
	add_theme_stylebox_override(&"pressed", _circle(pressed_color, true))
	add_theme_stylebox_override(&"disabled", _circle(UiStyle.DISABLED, false))
	add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	_glyph = Control.new()
	_glyph.name = "Glyph"
	_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glyph.draw.connect(_draw_glyph)
	add_child(_glyph)
	pressed.connect(func() -> void: Events.ui_clicked.emit())


func _draw_glyph() -> void:
	var c: Vector2 = _glyph.size * 0.5
	var ink: Color = UiStyle.IVORY if not disabled else Color(1, 1, 1, 0.7)
	var w: float = 13.0
	match kind:
		Kind.CHECK:
			_glyph.draw_polyline(PackedVector2Array([c + Vector2(-26, 2), c + Vector2(-8, 22), c + Vector2(28, -22)]), ink, w, true)
		Kind.CROSS:
			_glyph.draw_line(c + Vector2(-22, -22), c + Vector2(22, 22), ink, w, true)
			_glyph.draw_line(c + Vector2(22, -22), c + Vector2(-22, 22), ink, w, true)


static func _circle(color: Color, pushed: bool) -> StyleBoxFlat:
	var box: StyleBoxFlat = UiStyle.button_box(color, pushed)
	box.set_corner_radius_all(int(SIZE * 0.5))
	box.set_content_margin_all(0)
	return box


## Vẽ lại biểu tượng (khi đổi trạng thái khóa).
func refresh_glyph() -> void:
	if _glyph != null:
		_glyph.queue_redraw()
