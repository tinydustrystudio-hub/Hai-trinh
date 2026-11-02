extends GutTest
## Phân biệt chạm, kéo (ngưỡng 12 px) và chụm hai ngón; lăn chuột để thu phóng.

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


func test_pinch_zooms_and_is_not_a_tap() -> void:
	_input.handle_event(_touch(0, Vector2(100, 100), true))
	assert_true(_input.handle_event(_touch(1, Vector2(300, 100), true)))
	assert_true(_input.is_pinching())
	assert_signal_emitted(_input, "pinch_started")
	# Hai ngón giãn từ 200 px ra 400 px: phóng to gấp đôi.
	_input.handle_event(_drag(1, Vector2(500, 100)))
	var params: Array = get_signal_parameters(_input, "zoomed")
	assert_almost_eq(params[0], 2.0, 0.0001)
	_input.handle_event(_touch(1, Vector2(500, 100), false))
	assert_signal_emitted(_input, "pinch_ended")
	# Ngón còn lại đi xa rồi nhấc: không thành kéo, không thành chạm.
	_input.handle_event(_drag(0, Vector2(400, 400)))
	_input.handle_event(_touch(0, Vector2(400, 400), false))
	assert_signal_not_emitted(_input, "tapped")
	assert_signal_not_emitted(_input, "drag_started")


func test_pinch_ends_a_running_drag() -> void:
	_input.handle_event(_touch(0, Vector2(0, 0), true))
	_input.handle_event(_drag(0, Vector2(50, 0)))
	assert_true(_input.is_dragging())
	_input.handle_event(_touch(1, Vector2(200, 0), true))
	assert_false(_input.is_dragging())
	assert_signal_emitted(_input, "drag_ended")
	assert_true(_input.is_pinching())


func test_pinch_closer_zooms_out() -> void:
	_input.handle_event(_touch(0, Vector2(0, 0), true))
	_input.handle_event(_touch(1, Vector2(400, 0), true))
	_input.handle_event(_drag(1, Vector2(100, 0)))
	assert_almost_eq(get_signal_parameters(_input, "zoomed")[0], 0.25, 0.0001)


func test_gesture_after_pinch_works_again() -> void:
	_input.handle_event(_touch(0, Vector2(0, 0), true))
	_input.handle_event(_touch(1, Vector2(100, 0), true))
	_input.handle_event(_touch(0, Vector2(0, 0), false))
	_input.handle_event(_touch(1, Vector2(100, 0), false))
	_input.handle_event(_touch(0, Vector2(10, 10), true))
	_input.handle_event(_touch(0, Vector2(10, 10), false))
	assert_signal_emitted_with_parameters(_input, "tapped", [Vector2(10, 10)])


func test_mouse_wheel_zooms() -> void:
	var wheel: InputEventMouseButton = InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	wheel.position = Vector2(640, 360)
	assert_true(_input.handle_event(wheel))
	assert_signal_emitted_with_parameters(_input, "zoomed", [TouchInput.WHEEL_STEP, Vector2(640, 360)])
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	_input.handle_event(wheel)
	assert_almost_eq(get_signal_parameters(_input, "zoomed")[0], 1.0 / TouchInput.WHEEL_STEP, 0.0001)


func test_canceled_touch_is_not_a_tap() -> void:
	_input.handle_event(_touch(0, Vector2(0, 0), true))
	var release: InputEventScreenTouch = _touch(0, Vector2(0, 0), false)
	release.canceled = true
	_input.handle_event(release)
	assert_signal_not_emitted(_input, "tapped")


func test_two_fingers_moving_up_tilt_the_camera() -> void:
	_input.handle_event(_touch(0, Vector2(900, 600), true))
	_input.handle_event(_touch(1, Vector2(1000, 600), true))
	# Cả hai ngón cùng vuốt lên 40 px: khoảng cách giữ nguyên nên không thu phóng, tâm đi lên nên nghiêng.
	_input.handle_event(_drag(0, Vector2(900, 580)))
	_input.handle_event(_drag(1, Vector2(1000, 580)))
	_input.handle_event(_drag(0, Vector2(900, 560)))
	_input.handle_event(_drag(1, Vector2(1000, 560)))
	assert_signal_emitted(_input, "tilted")
	var total: float = _tilt_total()
	assert_almost_eq(total, 40.0, 0.01, "tổng vuốt lên 40 px")


func test_two_fingers_moving_down_tilt_the_other_way() -> void:
	_input.handle_event(_touch(0, Vector2(900, 500), true))
	_input.handle_event(_touch(1, Vector2(1000, 500), true))
	_input.handle_event(_drag(0, Vector2(900, 530)))
	_input.handle_event(_drag(1, Vector2(1000, 530)))
	var total: float = _tilt_total()
	assert_lt(total, 0.0)


func test_one_finger_never_tilts() -> void:
	_input.handle_event(_touch(0, Vector2(900, 500), true))
	_input.handle_event(_drag(0, Vector2(900, 400)))
	assert_signal_not_emitted(_input, "tilted")


func test_shift_wheel_tilts_and_plain_wheel_zooms() -> void:
	var wheel: InputEventMouseButton = InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	wheel.shift_pressed = true
	_input.handle_event(wheel)
	assert_signal_emitted_with_parameters(_input, "tilted", [TouchInput.WHEEL_TILT_PIXELS])
	assert_signal_not_emitted(_input, "zoomed")
	wheel.shift_pressed = false
	_input.handle_event(wheel)
	assert_signal_emitted(_input, "zoomed")


func _tilt_total() -> float:
	var total: float = 0.0
	for i: int in get_signal_emit_count(_input, "tilted"):
		total += get_signal_parameters(_input, "tilted", i)[0]
	return total
