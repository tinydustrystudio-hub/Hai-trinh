class_name BuildRing
extends Control
## Vòng chọn lô cốt mở quanh bệ vừa chạm (GDD mục 7.10): mỗi lô cốt một nút tròn kèm giá Thép;
## thiếu Tiền Vàng thì nút xám và không bấm được. Chạm một lô cốt chỉ để xem trước: hiện tầm bắn trên bệ và hai nút
## tròn nhỏ có biểu tượng, dấu tích (xây) và dấu nhân (hủy), đặt ngay cạnh bệ (người duyệt 1/11). Giá nằm trên nút
## lô cốt đang chọn và trong chú giải của nút xây. Nút tối thiểu 120 px.

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
## Tâm cặp nút xác nhận so với bệ, thử theo thứ tự, lấy chỗ đầu tiên lọt màn hình và không đè nút lô cốt.
const CONFIRM_OFFSETS: Array[Vector2] = [Vector2(0, 100), Vector2(0, 125), Vector2(0, -330), Vector2(230, 20), Vector2(-230, 20), Vector2(0, 175)]
const GAP: float = 16.0

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
	_confirm = IconButton.new()
	_confirm.name = "Confirm"
	(_confirm as IconButton).setup(IconButton.Kind.CHECK, UiStyle.RESCUE_ORANGE, UiStyle.PRIMARY_PRESSED)
	_confirm.pressed.connect(_on_confirm)
	add_child(_confirm)
	_cancel = IconButton.new()
	_cancel.name = "Cancel"
	(_cancel as IconButton).setup(IconButton.Kind.CROSS, UiStyle.GRAPHITE.lightened(0.1), UiStyle.GRAPHITE.darkened(0.1))
	_cancel.pressed.connect(_on_cancel)
	add_child(_cancel)
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


## Đặt hai nút tròn cạnh bệ ở chỗ trống đầu tiên: lọt màn hình và không đè các nút lô cốt.
func _place_confirm_buttons() -> void:
	if _confirm == null:
		return
	var screen: Vector2 = get_viewport_rect().size
	var full: Rect2 = Rect2(Vector2.ZERO, screen)
	var pair: Vector2 = Vector2(IconButton.SIZE * 2.0 + GAP, IconButton.SIZE)
	for offset: Vector2 in CONFIRM_OFFSETS:
		var left: Vector2 = anchor + offset - pair * 0.5
		var area: Rect2 = Rect2(left, pair)
		if not full.encloses(area.grow(UiStyle.MARGIN * 0.25)):
			continue
		if _overlaps_options(area):
			continue
		_set_pair(left)
		return
	# Không chỗ nào hợp lệ: ép vào trong màn hình ở vị trí đầu tiên.
	var fallback: Vector2 = anchor + CONFIRM_OFFSETS[0] - pair * 0.5
	_set_pair(Vector2(clampf(fallback.x, UiStyle.MARGIN, screen.x - pair.x - UiStyle.MARGIN), clampf(fallback.y, UiStyle.MARGIN, screen.y - pair.y - UiStyle.MARGIN)))


func _set_pair(left: Vector2) -> void:
	_cancel.position = left
	_confirm.position = left + Vector2(IconButton.SIZE + GAP, 0.0)
	_cancel.size = Vector2(IconButton.SIZE, IconButton.SIZE)
	_confirm.size = Vector2(IconButton.SIZE, IconButton.SIZE)


func _overlaps_options(area: Rect2) -> bool:
	for button: Button in _buttons:
		if Rect2(button.position, button.size).grow(GAP * 0.5).intersects(area):
			return true
	return false


## Nút xác nhận và hủy chỉ hiện khi đã chọn một lô cốt; nút xác nhận xám nếu thiếu Tiền Vàng.
func _refresh_confirm() -> void:
	if _confirm == null:
		return
	var showing: bool = previewed != null
	_confirm.visible = showing
	_cancel.visible = showing
	if showing:
		_place_confirm_buttons()
		_confirm.tooltip_text = "%s %s %d" % [tr(&"BUILD_CONFIRM"), tr(previewed.name_key), previewed.level(1).steel_cost]
		_confirm.disabled = previewed.level(1).steel_cost > _steel
		(_confirm as IconButton).refresh_glyph()


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
