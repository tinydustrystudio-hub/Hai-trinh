class_name BuildRing
extends Control
## Vòng chọn lô cốt mở quanh bệ vừa chạm (GDD mục 7.10): mỗi lô cốt một nút tròn kèm giá Thép;
## thiếu Thép thì nút xám và không bấm được. Nút tối thiểu 120 px.

## Người chơi bấm Xây sau khi đã chọn một lô cốt.
signal tower_chosen(data: TowerData)
## Người chơi chạm một lô cốt trong vòng để xem tầm bắn (chưa xây).
signal option_previewed(data: TowerData)
signal cancelled

const BUTTON_SIZE: float = 168.0
## Khoảng cách từ bệ tới tâm các nút.
const RADIUS: float = 165.0
## Các nút xếp trên cung phía trên bệ, từ trái sang phải.
const ARC_DEGREES: float = 70.0
const CONFIRM_SIZE: Vector2 = Vector2(360, 150)
const CANCEL_SIZE: Vector2 = Vector2(240, 150)
## Chừa chỗ cho khay MEGA (nút 150 px) ở sát đáy.
const TRAY_CLEARANCE: float = 150.0 + 24.0

var options: Array[TowerData] = []
var anchor: Vector2 = Vector2.ZERO

## Lô cốt đang xem trước, hoặc null.
var previewed: TowerData = null

var _buttons: Array[Button] = []
var _steel: int = 0
var _confirm: Button
var _cancel: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm = UiStyle.primary_button(&"BUILD_CONFIRM", CONFIRM_SIZE)
	_confirm.name = "Confirm"
	_confirm.add_theme_font_size_override(&"font_size", 38)
	_confirm.pressed.connect(_on_confirm)
	add_child(_confirm)
	_cancel = UiStyle.primary_button(&"BUILD_CANCEL", CANCEL_SIZE)
	_cancel.name = "Cancel"
	_cancel.pressed.connect(_on_cancel)
	add_child(_cancel)
	_place_confirm_buttons()
	get_viewport().size_changed.connect(_place_confirm_buttons)
	visible = false


## Mở vòng quanh điểm screen_position với các lựa chọn và số Thép hiện có.
func open(at: Vector2, choices: Array[TowerData], steel: int) -> void:
	options = choices
	anchor = at
	_steel = steel
	previewed = null
	_rebuild()
	_refresh_confirm()
	visible = true


func close() -> void:
	previewed = null
	visible = false


func is_open() -> bool:
	return visible


## Cập nhật nút xám hay sáng khi Thép đổi.
func set_steel(value: int) -> void:
	_steel = value
	for i: int in _buttons.size():
		_style(_buttons[i], options[i])
	_refresh_confirm()


func confirm_button() -> Button:
	return _confirm


func cancel_button() -> Button:
	return _cancel


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
	# Lô cốt đang xem trước nổi lên một chút để dễ thấy.
	button.modulate = Color(1.0, 1.0, 1.0) if data == previewed or previewed == null else Color(0.78, 0.78, 0.78)


func _place_confirm_buttons() -> void:
	if _confirm == null:
		return
	var screen: Vector2 = get_viewport_rect().size
	var bottom: float = screen.y - UiStyle.MARGIN * 2 - TRAY_CLEARANCE
	_confirm.size = CONFIRM_SIZE
	_cancel.size = CANCEL_SIZE
	_confirm.position = Vector2(screen.x - UiStyle.MARGIN * 2 - CONFIRM_SIZE.x, bottom - CONFIRM_SIZE.y)
	_cancel.position = Vector2(_confirm.position.x - 16.0 - CANCEL_SIZE.x, bottom - CANCEL_SIZE.y)


## Nút Xây và Hủy chỉ hiện khi đã chọn một lô cốt; Xây xám nếu thiếu Thép.
func _refresh_confirm() -> void:
	if _confirm == null:
		return
	var showing: bool = previewed != null
	_confirm.visible = showing
	_cancel.visible = showing
	if showing:
		_confirm.text = "%s\n%s %d" % [tr(&"BUILD_CONFIRM"), tr(previewed.name_key), previewed.level(1).steel_cost]
		_confirm.disabled = previewed.level(1).steel_cost > _steel


func _on_pressed(data: TowerData) -> void:
	if data.level(1).steel_cost > _steel:
		return
	previewed = data
	for i: int in _buttons.size():
		_style(_buttons[i], options[i])
	_refresh_confirm()
	option_previewed.emit(data)


func _on_confirm() -> void:
	if previewed != null and previewed.level(1).steel_cost <= _steel:
		tower_chosen.emit(previewed)


func _on_cancel() -> void:
	cancelled.emit()
