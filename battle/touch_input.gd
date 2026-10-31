class_name TouchInput
extends Node
## Đọc chạm (chuột trên máy tính được giả lập thành chạm) và phân biệt ba cử chỉ:
## - chạm: một ngón, đi chưa quá DRAG_THRESHOLD (px ở độ phân giải gốc) rồi nhấc;
## - kéo: một ngón đi quá DRAG_THRESHOLD;
## - chụm: hai ngón; phát zoomed theo tỉ lệ khoảng cách hai ngón. Lăn chuột cũng phát zoomed.
## Đã chụm thì tới khi nhấc hết ngón không tính là chạm hay kéo nữa.
## Chỉ nhận chạm chưa bị giao diện dùng (_unhandled_input).

signal tapped(screen_position: Vector2)
signal drag_started(screen_position: Vector2)
signal drag_moved(screen_position: Vector2)
signal drag_ended(screen_position: Vector2)
signal pinch_started
signal pinch_ended
## factor > 1 là phóng to; screen_position là tâm cử chỉ.
signal zoomed(factor: float, screen_position: Vector2)

const DRAG_THRESHOLD: float = 12.0
## Mỗi nấc lăn chuột phóng hoặc thu theo hệ số này.
const WHEEL_STEP: float = 1.15

## Vị trí hiện tại của từng ngón đang chạm, theo chỉ số ngón.
var _fingers: Dictionary[int, Vector2] = {}
var _press_position: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _pinching: bool = false
## Cử chỉ hiện tại đã thành chụm: bỏ qua mọi chạm và kéo tới khi nhấc hết ngón.
var _blocked: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if handle_event(event):
		get_viewport().set_input_as_handled()


## Xử lý một sự kiện; trả true nếu đã dùng nó.
func handle_event(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return _on_touch(event)
	if event is InputEventScreenDrag:
		return _on_drag(event)
	if event is InputEventMouseButton:
		var button: InputEventMouseButton = event
		if not button.pressed:
			return false
		if button.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoomed.emit(WHEEL_STEP, button.position)
			return true
		if button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoomed.emit(1.0 / WHEEL_STEP, button.position)
			return true
		return false
	if event is InputEventMagnifyGesture:
		var magnify: InputEventMagnifyGesture = event
		zoomed.emit(magnify.factor, magnify.position)
		return true
	return false


func is_dragging() -> bool:
	return _dragging


func is_pinching() -> bool:
	return _pinching


func _on_touch(touch: InputEventScreenTouch) -> bool:
	if touch.pressed:
		_fingers[touch.index] = touch.position
		if _fingers.size() == 1 and not _blocked:
			_press_position = touch.position
			_dragging = false
		elif _fingers.size() == 2:
			_start_pinch()
		return true
	if not _fingers.has(touch.index):
		return false
	_fingers.erase(touch.index)
	if _pinching:
		_pinching = false
		pinch_ended.emit()
	if _fingers.is_empty():
		var was_blocked: bool = _blocked
		_blocked = false
		if was_blocked:
			return true
		if _dragging:
			_dragging = false
			drag_ended.emit(touch.position)
		elif not touch.canceled:
			tapped.emit(touch.position)
	return true


func _on_drag(drag: InputEventScreenDrag) -> bool:
	if not _fingers.has(drag.index):
		return false
	if _pinching:
		var before: float = _pinch_span()
		var center_before: Vector2 = _pinch_center()
		_fingers[drag.index] = drag.position
		var after: float = _pinch_span()
		if before > 0.0 and after > 0.0:
			zoomed.emit(after / before, center_before.lerp(_pinch_center(), 0.5))
		return true
	_fingers[drag.index] = drag.position
	if _blocked:
		return true
	if not _dragging:
		if drag.position.distance_to(_press_position) < DRAG_THRESHOLD:
			return true
		_dragging = true
		drag_started.emit(_press_position)
	drag_moved.emit(drag.position)
	return true


func _start_pinch() -> void:
	if _dragging:
		_dragging = false
		drag_ended.emit(_press_position)
	_pinching = true
	_blocked = true
	pinch_started.emit()


## Khoảng cách giữa hai ngón đầu tiên.
func _pinch_span() -> float:
	var points: Array[Vector2] = _fingers.values()
	return points[0].distance_to(points[1]) if points.size() >= 2 else 0.0


func _pinch_center() -> Vector2:
	var points: Array[Vector2] = _fingers.values()
	return (points[0] + points[1]) * 0.5 if points.size() >= 2 else Vector2.ZERO
