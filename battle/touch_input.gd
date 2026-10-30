class_name TouchInput
extends Node
## Đọc chạm của một ngón (chuột trên máy tính được giả lập thành chạm) và phân biệt chạm với kéo:
## ngón tay đi quá DRAG_THRESHOLD (px ở độ phân giải gốc) thì thành kéo. Ngón thứ hai bị bỏ qua.
## Chỉ nhận chạm chưa bị giao diện dùng (_unhandled_input).

signal tapped(screen_position: Vector2)
signal drag_started(screen_position: Vector2)
signal drag_moved(screen_position: Vector2)
signal drag_ended(screen_position: Vector2)

const DRAG_THRESHOLD: float = 12.0

var _finger: int = -1
var _press_position: Vector2 = Vector2.ZERO
var _dragging: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if handle_event(event):
		get_viewport().set_input_as_handled()


## Xử lý một sự kiện; trả true nếu đã dùng nó.
func handle_event(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			if _finger != -1:
				return false
			_finger = touch.index
			_press_position = touch.position
			_dragging = false
			return true
		if touch.index != _finger:
			return false
		_finger = -1
		if _dragging:
			_dragging = false
			drag_ended.emit(touch.position)
		elif not touch.canceled:
			tapped.emit(touch.position)
		return true
	if event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if drag.index != _finger:
			return false
		if not _dragging:
			if drag.position.distance_to(_press_position) < DRAG_THRESHOLD:
				return true
			_dragging = true
			drag_started.emit(_press_position)
		drag_moved.emit(drag.position)
		return true
	return false


func is_dragging() -> bool:
	return _dragging
