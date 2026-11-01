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
