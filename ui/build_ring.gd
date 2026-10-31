class_name BuildRing
extends Control
## Vòng chọn lô cốt mở quanh bệ vừa chạm (GDD mục 7.10): mỗi lô cốt một nút tròn kèm giá Thép;
## thiếu Thép thì nút xám và không bấm được. Nút tối thiểu 120 px.

signal tower_chosen(data: TowerData)

const BUTTON_SIZE: float = 168.0
## Khoảng cách từ bệ tới tâm các nút.
const RADIUS: float = 165.0
## Các nút xếp trên cung phía trên bệ, từ trái sang phải.
const ARC_DEGREES: float = 70.0

var options: Array[TowerData] = []
var anchor: Vector2 = Vector2.ZERO

var _buttons: Array[Button] = []
var _steel: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false


## Mở vòng quanh điểm screen_position với các lựa chọn và số Thép hiện có.
func open(at: Vector2, choices: Array[TowerData], steel: int) -> void:
	options = choices
	anchor = at
	_steel = steel
	_rebuild()
	visible = true


func close() -> void:
	visible = false


func is_open() -> bool:
	return visible


## Cập nhật nút xám hay sáng khi Thép đổi.
func set_steel(value: int) -> void:
	_steel = value
	for i: int in _buttons.size():
		_style(_buttons[i], options[i])


func buttons() -> Array[Button]:
	return _buttons


## Tâm nút thứ index trong count nút, quanh anchor, đã kẹp trong màn hình rộng screen.
static func button_center(index: int, count: int, at: Vector2, screen: Vector2) -> Vector2:
	var spread: float = deg_to_rad(ARC_DEGREES) * float(count - 1)
	var angle: float = -PI * 0.5 - spread * 0.5 + (spread / float(maxi(count - 1, 1))) * float(index)
	var center: Vector2 = at + Vector2(cos(angle), sin(angle)) * RADIUS
	var half: float = BUTTON_SIZE * 0.5 + 8.0
	return Vector2(clampf(center.x, half, screen.x - half), clampf(center.y, half, screen.y - half))


func _rebuild() -> void:
	for button: Button in _buttons:
		button.queue_free()
	_buttons.clear()
	var screen: Vector2 = get_viewport_rect().size
	for i: int in options.size():
		var data: TowerData = options[i]
		var button: Button = UiStyle.primary_button(&"", Vector2(BUTTON_SIZE, BUTTON_SIZE))
		button.size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
		button.position = button_center(i, options.size(), anchor, screen) - button.size * 0.5
		button.add_theme_font_size_override(&"font_size", 30)
		button.text = "%s\n%d" % [tr(data.name_key), data.level(1).steel_cost]
		button.pressed.connect(_on_pressed.bind(data))
		add_child(button)
		_buttons.append(button)
		_style(button, data)


func _style(button: Button, data: TowerData) -> void:
	var affordable: bool = data.level(1).steel_cost <= _steel
	button.disabled = not affordable
	

func _on_pressed(data: TowerData) -> void:
	if data.level(1).steel_cost <= _steel:
		tower_chosen.emit(data)
