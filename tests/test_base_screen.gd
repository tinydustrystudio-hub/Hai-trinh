extends GutTest
## Màn Căn cứ: ví, cấp công trình, nút nâng cấp, đảo xem trước, nút tối thiểu 120 px, nút chính ở góc dưới phải.

var _screen: BaseScreen


func before_each() -> void:
	TranslationServer.set_locale("vi")
	Profile.reset_to_new()
	_screen = BaseScreen.new()
	add_child_autofree(_screen)
	await wait_process_frames(2)


func after_all() -> void:
	Profile.reset_to_new()


func test_shows_wallet_and_levels() -> void:
	assert_eq(_screen.wallet_text(), str(Profile.NEW_PLAYER_GOLD))
	assert_eq(_screen.level_text(&"wave_shield"), "Cấp 1/5")
	assert_eq(_screen.upgrade_button(&"wave_shield").text, "Nâng cấp 200")


func test_upgrade_button_spends_and_updates() -> void:
	_screen.upgrade_button(&"wave_shield").pressed.emit()
	assert_eq(Profile.level_of(&"wave_shield"), 2)
	assert_eq(_screen.level_text(&"wave_shield"), "Cấp 2/5")
	assert_eq(_screen.wallet_text(), str(Profile.NEW_PLAYER_GOLD - 200))


func test_button_disabled_when_poor_or_max() -> void:
	Profile.set_gold(50)
	_screen.refresh()
	assert_true(_screen.upgrade_button(&"wave_shield").disabled)
	Profile.set_gold(100000)
	Profile.building_levels[&"wave_shield"] = BuildingData.MAX_LEVEL
	_screen.refresh()
	assert_true(_screen.upgrade_button(&"wave_shield").disabled)
	assert_eq(_screen.upgrade_button(&"wave_shield").text, "Cấp tối đa")


func test_preview_island_follows_levels() -> void:
	var before: int = _screen.island().get_node("Body/Fortress").mesh.surface_get_array_len(0)
	Profile.building_levels[&"shipyard"] = 5
	Profile.building_levels[&"wave_shield"] = 5
	_screen.refresh()
	var after: int = _screen.island().get_node("Body/Fortress").mesh.surface_get_array_len(0)
	assert_gt(after, before)


func test_buttons_big_enough_and_primary_bottom_right() -> void:
	var screen: Rect2 = _screen.get_viewport_rect()
	for button: Button in [_screen.play_button(), _screen.back_button(), _screen.upgrade_button(&"shipyard")]:
		assert_gte(button.size.x, 120.0)
		assert_gte(button.size.y, 120.0)
	var go: Rect2 = _screen.play_button().get_global_rect()
	assert_true(screen.encloses(go))
	assert_gt(go.get_center().x, screen.size.x * 0.5)
	var back: Rect2 = _screen.back_button().get_global_rect()
	assert_lt(back.get_center().x, screen.size.x * 0.5)
	assert_false(go.intersects(back))


func test_title_has_base_button() -> void:
	var title: TitleScreen = TitleScreen.new()
	add_child_autofree(title)
	await wait_process_frames(2)
	watch_signals(title)
	title.base_button().pressed.emit()
	assert_signal_emitted(title, "base_requested")
	assert_false(title.base_button().get_global_rect().intersects(title.settings_button().get_global_rect()))


func test_preview_rotates_on_drag() -> void:
	var before: float = _screen.yaw()
	var drag: InputEventMouseMotion = InputEventMouseMotion.new()
	drag.relative = Vector2(100, 0)
	drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	_screen.get_node("Preview").gui_input.emit(drag)
	assert_ne(_screen.yaw(), before)
	var hover: InputEventMouseMotion = InputEventMouseMotion.new()
	hover.relative = Vector2(100, 0)
	var after_drag: float = _screen.yaw()
	_screen.get_node("Preview").gui_input.emit(hover)
	assert_eq(_screen.yaw(), after_drag, "di chuột không bấm thì không xoay")


func test_reset_buttons_for_testing() -> void:
	Profile.set_gold(40)
	Profile.building_levels[&"shipyard"] = 4
	_screen.reset_levels_button().pressed.emit()
	assert_eq(Profile.level_of(&"shipyard"), 1)
	assert_eq(Profile.gold, 40, "đặt lại cấp giữ nguyên vàng")
	_screen.reset_gold_button().pressed.emit()
	assert_eq(Profile.gold, Profile.NEW_PLAYER_GOLD)
	_screen.add_gold_button().pressed.emit()
	assert_eq(Profile.gold, Profile.NEW_PLAYER_GOLD + BaseScreen.TEST_GOLD)
	assert_eq(_screen.wallet_text(), str(Profile.gold))
	for button: Button in [_screen.reset_gold_button(), _screen.reset_levels_button(), _screen.add_gold_button()]:
		assert_gte(button.size.y, 120.0)


func test_test_buttons_do_not_overlap_main_buttons() -> void:
	var rects: Array[Rect2] = [_screen.play_button().get_global_rect(), _screen.back_button().get_global_rect()]
	for button: Button in [_screen.reset_gold_button(), _screen.reset_levels_button(), _screen.add_gold_button()]:
		for rect: Rect2 in rects:
			assert_false(button.get_global_rect().intersects(rect))
		assert_true(_screen.get_viewport_rect().encloses(button.get_global_rect()))


func test_preview_zoom_wheel_pinch_and_limits() -> void:
	var preview: Control = _screen.get_node("Preview")
	var wheel: InputEventMouseButton = InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	preview.gui_input.emit(wheel)
	assert_lt(_screen.distance_factor(), 1.0, "lăn lên là phóng to")
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	preview.gui_input.emit(wheel)
	assert_almost_eq(_screen.distance_factor(), 1.0, 0.001)
	# Chụm hai ngón xa ra thì phóng to.
	for index: int in 2:
		var touch: InputEventScreenTouch = InputEventScreenTouch.new()
		touch.index = index
		touch.pressed = true
		touch.position = Vector2(100 + index * 100, 100)
		preview.gui_input.emit(touch)
	var spread: InputEventScreenDrag = InputEventScreenDrag.new()
	spread.index = 1
	spread.position = Vector2(400, 100)
	preview.gui_input.emit(spread)
	assert_lt(_screen.distance_factor(), 1.0)
	# Đang chụm thì kéo chuột giả lập không xoay.
	var yaw: float = _screen.yaw()
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.relative = Vector2(200, 0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	preview.gui_input.emit(motion)
	assert_eq(_screen.yaw(), yaw)
	for i: int in 40:
		_screen.zoom_preview(1.5)
	assert_gte(_screen.distance_factor(), BaseScreen.MIN_DISTANCE)
	for i: int in 80:
		_screen.zoom_preview(0.5)
	assert_lte(_screen.distance_factor(), BaseScreen.MAX_DISTANCE)


func test_preview_tilts_with_vertical_drag_within_limits() -> void:
	var before: float = _screen.pitch()
	var drag: InputEventMouseMotion = InputEventMouseMotion.new()
	drag.relative = Vector2(0, 60)
	drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	_screen.get_node("Preview").gui_input.emit(drag)
	assert_gt(_screen.pitch(), before, "kéo xuống thì nhìn cao hơn")
	drag.relative = Vector2(0, -60)
	_screen.get_node("Preview").gui_input.emit(drag)
	assert_almost_eq(_screen.pitch(), before, 0.001)
	for i: int in 200:
		_screen.tilt_preview(0.2)
	assert_lte(_screen.pitch(), BaseScreen.MAX_PITCH)
	for i: int in 400:
		_screen.tilt_preview(-0.2)
	assert_gte(_screen.pitch(), BaseScreen.MIN_PITCH)


func test_default_pitch_matches_old_camera_angle() -> void:
	assert_almost_eq(BaseScreen.DEFAULT_PITCH, atan2(64.0, 55.0), 0.001)
