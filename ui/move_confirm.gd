class_name MoveConfirm
extends Control
## Dời lô cốt: dòng chỉ dẫn "Chạm bệ trống để dời" và, khi đã chọn bệ đích, hai nút tròn xác nhận (dấu tích) và huỷ (dấu nhân)
## đặt cạnh bệ đích kèm phí dời. Nút xác nhận xám nếu thiếu vàng. Nút từ 120 px.

signal confirmed
signal cancelled

const GAP: float = 16.0

var _hint: Label
var _confirm: IconButton
var _cancel: IconButton
var _cost: int = 0
var _flash_left: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_hint = UiStyle.label(UiStyle.TEXT_SIZE - 6)
	_hint.name = "Hint"
	_hint.add_theme_color_override(&"font_color", UiStyle.RESCUE_ORANGE.lightened(0.3))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 48)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)
	_confirm = IconButton.new()
	_confirm.name = "Confirm"
	_confirm.setup(IconButton.Kind.CHECK, UiStyle.RESCUE_ORANGE, UiStyle.PRIMARY_PRESSED)
	_confirm.pressed.connect(func() -> void: confirmed.emit())
	add_child(_confirm)
	_cancel = IconButton.new()
	_cancel.name = "Cancel"
	_cancel.setup(IconButton.Kind.CROSS, UiStyle.GRAPHITE.lightened(0.1), UiStyle.GRAPHITE.darkened(0.1))
	_cancel.pressed.connect(func() -> void: cancelled.emit())
	add_child(_cancel)
	close()


## Thông báo ngắn (ví dụ thiếu vàng) ở dòng chỉ dẫn, tự tắt sau vài giây.
func flash(text: String) -> void:
	_hint.text = text
	visible = true
	_confirm.visible = false
	_cancel.visible = false
	_flash_left = 2.0


func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			close()


func is_flashing() -> bool:
	return _flash_left > 0.0


## Bắt đầu chế độ dời: chỉ hiện dòng chỉ dẫn với phí dời cost.
func prompt(cost: int) -> void:
	_cost = cost
	_hint.text = tr(&"MOVE_PROMPT") % cost
	_confirm.visible = false
	_cancel.visible = false
	visible = true


## Đã chọn bệ đích ở điểm at trên màn hình: hiện hai nút cạnh đó; steel là vàng hiện có.
func place(at: Vector2, steel: int) -> void:
	var screen: Vector2 = get_viewport_rect().size
	var pair: Vector2 = Vector2(IconButton.SIZE * 2.0 + GAP, IconButton.SIZE)
	var left: Vector2 = at + Vector2(0.0, 150.0) - pair * 0.5
	left = Vector2(clampf(left.x, UiStyle.MARGIN, screen.x - pair.x - UiStyle.MARGIN), clampf(left.y, UiStyle.MARGIN, screen.y - pair.y - UiStyle.MARGIN))
	_cancel.position = left
	_confirm.position = left + Vector2(IconButton.SIZE + GAP, 0.0)
	_confirm.disabled = steel < _cost
	_confirm.visible = true
	_cancel.visible = true
	_confirm.refresh_glyph()
	_hint.text = tr(&"MOVE_CONFIRM") % _cost


func set_steel(steel: int) -> void:
	if visible and _confirm != null and _confirm.visible:
		_confirm.disabled = steel < _cost
		_confirm.refresh_glyph()


func close() -> void:
	_flash_left = 0.0
	visible = false


func confirm_button() -> Button:
	return _confirm


func cancel_button() -> Button:
	return _cancel
