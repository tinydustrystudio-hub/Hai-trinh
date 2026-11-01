class_name BuoyancyBar
extends VBoxContainer
## Độ Nổi ở góc trên trái (GDD mục 7.10): dòng số và một thanh đổi từ xanh sang đỏ khi mất dần.

const BAR_SIZE: Vector2 = Vector2(380, 26)
const FULL: Color = Color(0.35, 0.85, 0.95)
const LOW: Color = Color(1.0, 0.3, 0.2)
const BACK: Color = Color(0.03, 0.08, 0.14, 0.85)

var ratio: float = 1.0

var _label: Label
var _back: ColorRect
var _fill: ColorRect


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override(&"separation", 6)
	_label = UiStyle.label()
	add_child(_label)
	_back = ColorRect.new()
	_back.color = BACK
	_back.custom_minimum_size = BAR_SIZE
	_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_back)
	_fill = ColorRect.new()
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back.add_child(_fill)
	set_value(1, 1)


func set_value(value: int, max_value: int) -> void:
	ratio = clampf(float(value) / float(maxi(max_value, 1)), 0.0, 1.0)
	_label.text = tr(&"HUD_BUOYANCY") % [value, max_value]
	_fill.position = Vector2(3, 3)
	_fill.size = Vector2((BAR_SIZE.x - 6.0) * ratio, BAR_SIZE.y - 6.0)
	_fill.color = LOW.lerp(FULL, ratio)


func text() -> String:
	return _label.text
