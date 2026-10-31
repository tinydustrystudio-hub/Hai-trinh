extends GutTest
## HUD đầy đủ (GDD mục 7.10, 7.11; kế hoạch bước 11): mọi nút từ 120 px và nằm đúng góc theo GDD mục 7.1;
## chữ đi qua bảng dịch; Tạm dừng, ×2, Gọi đợt sớm hoạt động; tự tạm dừng khi mất tiêu điểm.

const BATTLE_SCENE: PackedScene = preload("res://battle/battle.tscn")
const MIN_BUTTON: float = 120.0

var _battle: BattleController
var _hud: Hud


func before_each() -> void:
	TranslationServer.set_locale("vi")
	_battle = add_child_autofree(BATTLE_SCENE.instantiate())
	_hud = _battle.hud
	await wait_process_frames(2)


func after_each() -> void:
	Engine.time_scale = 1.0


func _screen() -> Rect2:
	return _hud.frame.get_viewport_rect()


func _assert_corner(button: Control, right: bool, bottom: bool, what: String) -> void:
	var rect: Rect2 = button.get_global_rect()
	var screen: Rect2 = _screen()
	assert_gte(rect.size.x, MIN_BUTTON, "%s: rộng từ 120 px" % what)
	assert_gte(rect.size.y, MIN_BUTTON, "%s: cao từ 120 px" % what)
	assert_true(screen.encloses(rect), "%s nằm trọn trong màn hình" % what)
	if right:
		assert_gt(rect.get_center().x, screen.size.x * 0.66, "%s ở bên phải" % what)
	else:
		assert_lt(rect.get_center().x, screen.size.x * 0.34, "%s ở bên trái" % what)
	if bottom:
		assert_gt(rect.get_center().y, screen.size.y * 0.66, "%s ở dưới" % what)
	else:
		assert_lt(rect.get_center().y, screen.size.y * 0.34, "%s ở trên" % what)


func test_top_right_pause_and_speed() -> void:
	_assert_corner(_hud.pause_button(), true, false, "Tạm dừng")
	_assert_corner(_hud.speed_button(), true, false, "×2")
	var gap: float = _hud.pause_button().get_global_rect().position.x - _hud.speed_button().get_global_rect().end.x
	assert_gte(gap, 8.0, "hai nút cách nhau ít nhất 8 px")


func test_call_wave_bottom_left_while_waiting() -> void:
	assert_true(_hud.call_wave_button().visible, "đang chờ đợt 1 thì có nút Gọi đợt sớm")
	_assert_corner(_hud.call_wave_button(), false, true, "Gọi đợt sớm")


func test_mega_tray_bottom_right() -> void:
	_battle.economy.reset(1000)
	var tower: Tower = _battle.build_tower(_battle.island.pads[0], load("res://data/towers/machine_gun.tres"))
	tower.overload.add_charge(1.0)
	await wait_process_frames(2)
	_assert_corner(_hud.mega_tray.buttons()[0], true, true, "MEGA")


func test_texts_are_translated() -> void:
	assert_eq(_hud.buoyancy_text(), "Độ Nổi: 20/20")
	assert_eq(_hud.steel_text(), "200")
	assert_string_contains(_hud.incoming_text(), "Đợt 1 tới sau")
	# Góp ý 3: hướng địch do đèn báo trên đảo chỉ, không ghi bằng chữ.
	assert_false(_hud.incoming_text().contains("Luồng"))
	assert_string_contains(_hud.incoming_text(), "Mặt biển")
	assert_eq(_hud.speed_button().text, "×1")
	TranslationServer.set_locale("en")
	_battle.economy.earn(5)
	assert_eq(_hud.steel_text(), "205")
	TranslationServer.set_locale("vi")


func test_wave_label_after_start() -> void:
	_battle.call_wave_early()
	_battle.step(0.1)
	assert_eq(_hud.wave_text(), "Đợt 1/5")
	assert_false(_hud.call_wave_button().visible, "đang đánh thì ẩn Gọi đợt sớm")


func test_call_wave_early_starts_next_wave_now() -> void:
	assert_eq(_battle.state, BattleController.State.PREPARING)
	_hud.call_wave_button().pressed.emit()
	_battle.step(0.05)
	assert_eq(_battle.state, BattleController.State.FIGHTING)
	assert_eq(_battle.enemy_pool.active_count(), 1)


func test_speed_button_toggles_two_x() -> void:
	_hud.speed_button().pressed.emit()
	assert_eq(Engine.time_scale, 2.0)
	assert_eq(_hud.speed_button().text, "×2")
	_hud.speed_button().pressed.emit()
	assert_eq(Engine.time_scale, 1.0)
	assert_eq(_hud.speed_button().text, "×1")


func test_pause_menu_layout_and_resume() -> void:
	_hud.pause_button().pressed.emit()
	assert_true(_battle.paused)
	assert_eq(Engine.time_scale, 0.0)
	assert_true(_hud.pause_menu.is_open())
	await wait_process_frames(2)
	for button: Button in _hud.pause_menu.buttons():
		var rect: Rect2 = button.get_global_rect()
		assert_gte(rect.size.x, MIN_BUTTON, button.text)
		assert_gte(rect.size.y, MIN_BUTTON, button.text)
		assert_true(_screen().encloses(rect), button.text)
	_assert_corner(_hud.pause_menu.resume_corner_button(), true, true, "Tiếp tục (góc)")
	var big: Rect2 = _hud.pause_menu.resume_big_button().get_global_rect()
	assert_almost_eq(big.get_center().x, _screen().get_center().x, 2.0, "Tiếp tục cỡ lớn ở giữa")
	_hud.pause_menu.resume_corner_button().pressed.emit()
	assert_false(_battle.paused)
	assert_eq(Engine.time_scale, 1.0)
	assert_false(_hud.pause_menu.is_open())


func test_pause_keeps_fast_speed_on_resume() -> void:
	_battle.toggle_fast()
	_battle.pause()
	assert_eq(Engine.time_scale, 0.0)
	_battle.resume()
	assert_eq(Engine.time_scale, 2.0)


func test_restart_from_pause() -> void:
	_battle.economy.spend(100)
	_battle.pause()
	_hud.pause_menu.buttons()[1].pressed.emit()
	assert_false(_battle.paused)
	assert_eq(_battle.economy.steel, 200)
	assert_false(_hud.pause_menu.is_open())


func test_quick_settings_toggle() -> void:
	var sound: bool = Settings.sound_enabled
	_battle.pause()
	_hud.pause_menu.buttons()[2].pressed.emit()
	assert_eq(Settings.sound_enabled, not sound)
	_hud.pause_menu.buttons()[2].pressed.emit()
	assert_eq(Settings.sound_enabled, sound)
	var music: bool = Settings.music_enabled
	_hud.pause_menu.buttons()[3].pressed.emit()
	assert_eq(Settings.music_enabled, not music)
	assert_string_contains(_hud.pause_menu.buttons()[3].text, "Nhạc")
	_hud.pause_menu.buttons()[3].pressed.emit()
	assert_eq(Settings.music_enabled, music)


func test_auto_pause_on_focus_lost() -> void:
	_battle.on_focus_lost()
	assert_true(_battle.paused)
	assert_true(_hud.pause_menu.is_open())


func test_escape_toggles_pause() -> void:
	var escape: InputEventAction = InputEventAction.new()
	escape.action = &"ui_cancel"
	escape.pressed = true
	_battle._unhandled_input(escape)
	assert_true(_battle.paused)
	_battle._unhandled_input(escape)
	assert_false(_battle.paused)


func test_enemy_cards_in_pause_menu() -> void:
	_battle.call_wave_early()
	_battle.step(0.1)
	assert_eq(_battle.enemy_tips().size(), 1)
	assert_string_contains(_battle.enemy_tips()[0], "Xuồng Cướp")


func test_no_pause_after_battle_ends() -> void:
	_battle.buoyancy.take_leak(100)
	assert_true(_battle.is_over())
	_battle.pause()
	assert_false(_battle.paused)
