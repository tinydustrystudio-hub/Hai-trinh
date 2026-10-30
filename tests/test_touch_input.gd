extends GutTest
## Phân biệt chạm và kéo theo ngưỡng 12 px; bỏ qua ngón thứ hai.

var _input: TouchInput


func before_each() -> void:
	_input = TouchInput.new()
	watch_signals(_input)


func after_each() -> void:
	_input.free()


func _touch(index: int, position: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	return event


func _drag(index: int, position: Vector2) -> InputEventScreenDrag:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.index = index
	event.position = position
	return event


func test_short_move_is_a_tap() -> void:
	_input.handle_event(_touch(0, Vector2(100, 100), true))
	_input.handle_event(_drag(0, Vector2(108, 104)))
	_input.handle_event(_touch(0, Vector2(108, 104), false))
	assert_signal_emitted_with_parameters(_input, "tapped", [Vector2(108, 104)])
	assert_signal_not_emitted(_input, "drag_started")


func test_long_move_is_a_drag() -> void:
	_input.handle_event(_touch(0, Vector2(100, 100), true))
	_input.handle_event(_drag(0, Vector2(113, 100)))
	_input.handle_event(_drag(0, Vector2(150, 100)))
	_input.handle_event(_touch(0, Vector2(150, 100), false))
	assert_signal_emitted_with_parameters(_input, "drag_started", [Vector2(100, 100)])
	assert_signal_emit_count(_input, "drag_moved", 2)
	assert_signal_emitted_with_parameters(_input, "drag_ended", [Vector2(150, 100)])
	assert_signal_not_emitted(_input, "tapped")


func test_threshold_is_twelve_pixels() -> void:
	_input.handle_event(_touch(0, Vector2(0, 0), true))
	_input.handle_event(_drag(0, Vector2(11.9, 0)))
	assert_false(_input.is_dragging())
	_input.handle_event(_drag(0, Vector2(12, 0)))
	assert_true(_input.is_dragging())


func test_second_finger_is_ignored() -> void:
	_input.handle_event(_touch(0, Vector2(0, 0), true))
	assert_false(_input.handle_event(_touch(1, Vector2(500, 500), true)))
	assert_false(_input.handle_event(_drag(1, Vector2(900, 500))))
	assert_false(_input.handle_event(_touch(1, Vector2(900, 500), false)))
	_input.handle_event(_touch(0, Vector2(0, 0), false))
	assert_signal_emit_count(_input, "tapped", 1)
	assert_signal_not_emitted(_input, "drag_started")


func test_canceled_touch_is_not_a_tap() -> void:
	_input.handle_event(_touch(0, Vector2(0, 0), true))
	var release: InputEventScreenTouch = _touch(0, Vector2(0, 0), false)
	release.canceled = true
	_input.handle_event(release)
	assert_signal_not_emitted(_input, "tapped")
