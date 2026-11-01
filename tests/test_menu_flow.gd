extends GutTest
## Luồng menu cốt lõi (P2): Tiêu đề → Chuẩn bị → Trận → Về menu; Cài đặt lưu máy; hướng dẫn vài bước đầu.

const BOOT_SCENE: PackedScene = preload("res://main/boot.tscn")
const TEST_SAVE: String = "user://test_settings.cfg"

var _boot: Node
var _saved: Dictionary


func before_each() -> void:
	TranslationServer.set_locale("vi")
	_saved = Settings.to_dictionary()
	_boot = add_child_autofree(BOOT_SCENE.instantiate())


func after_each() -> void:
	Settings.apply_dictionary(_saved)
	TranslationServer.set_locale("vi")
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))


func _screen() -> Rect2:
	return get_viewport().get_visible_rect()


func _rect_in_screen(button: Control) -> bool:
	return _screen().encloses(button.get_global_rect())


func test_boot_stays_idle_when_not_main_scene() -> void:
	assert_null(_boot.current)


func test_title_screen_buttons_and_layout() -> void:
	var title: TitleScreen = _boot.show_title()
	await wait_process_frames(2)
	assert_eq(title.get_node("Title").text, "Hải Trình")
	for button: Button in [title.play_button(), title.settings_button()]:
		assert_gte(button.size.x, 120.0)
		assert_gte(button.size.y, 120.0)
		assert_true(_rect_in_screen(button))
	var play: Rect2 = title.play_button().get_global_rect()
	var screen: Rect2 = _screen()
	assert_gt(play.get_center().x, screen.size.x * 0.6, "hành động chính ở góc dưới phải")
	assert_gt(play.get_center().y, screen.size.y * 0.7)
	assert_lt(title.settings_button().get_global_rect().get_center().x, screen.size.x * 0.4, "Cài đặt ở góc dưới trái")


func test_play_goes_to_prep_then_battle_then_menu() -> void:
	var title: TitleScreen = _boot.show_title()
	title.play_button().pressed.emit()
	await wait_process_frames(2)
	assert_true(_boot.current is PrepScreen)
	var prep: PrepScreen = _boot.current
	prep.back_button().pressed.emit()
	await wait_process_frames(2)
	assert_true(_boot.current is TitleScreen, "Quay lại về tiêu đề")
	_boot.show_prep()
	await wait_process_frames(2)
	_boot.current.start_button().pressed.emit()
	await wait_process_frames(2)
	assert_true(_boot.current is BattleController)
	var battle: BattleController = _boot.current
	battle.menu_requested.emit()
	await wait_process_frames(2)
	assert_true(_boot.current is TitleScreen)
	assert_eq(Engine.time_scale, 1.0)


func test_prep_screen_lists_enemies_and_towers() -> void:
	var prep: PrepScreen = _boot.show_prep()
	await wait_process_frames(2)
	assert_eq(prep.enemy_lines().size(), 3)
	assert_has(Array(prep.enemy_lines()), "Cua Giáp Gai")
	assert_eq(prep.tower_lines().size(), 3)
	assert_has(Array(prep.tower_lines()), "Súng Máy – 70")
	assert_string_contains(prep.find_child("Objective", true, false).text, "5 đợt")
	var go: Rect2 = prep.start_button().get_global_rect()
	assert_true(_rect_in_screen(prep.start_button()))
	assert_gt(go.get_center().x, _screen().size.x * 0.6, "Xuất kích ở góc dưới phải")
	assert_gt(go.get_center().y, _screen().size.y * 0.7)
	assert_true(_rect_in_screen(prep.back_button()))


func test_settings_toggle_and_back() -> void:
	var screen: SettingsScreen = _boot.show_settings()
	await wait_process_frames(2)
	var sound: bool = Settings.sound_enabled
	screen.row(&"sound").pressed.emit()
	assert_eq(Settings.sound_enabled, not sound)
	assert_string_contains(screen.row(&"sound").text, "Âm thanh")
	screen.row(&"music").pressed.emit()
	screen.row(&"vibration").pressed.emit()
	var quality: Ocean.Quality = Settings.water_quality
	screen.row(&"water").pressed.emit()
	assert_ne(Settings.water_quality, quality)
	for key: StringName in [&"sound", &"music", &"vibration", &"water", &"language", &"tutorial"]:
		assert_gte(screen.row(key).size.y, 120.0)
		assert_true(_rect_in_screen(screen.row(key)), String(key))
	screen.back_button().pressed.emit()
	await wait_process_frames(2)
	assert_true(_boot.current is TitleScreen)


func test_language_switch_translates_screen() -> void:
	var screen: SettingsScreen = _boot.show_settings()
	await wait_process_frames(2)
	assert_eq(Settings.language, "vi")
	screen.row(&"language").pressed.emit()
	assert_eq(Settings.language, "en")
	assert_eq(TranslationServer.get_locale().substr(0, 2), "en")
	assert_string_contains(screen.row(&"language").text, "English")
	assert_eq(screen.back_button().text, "Back")
	screen.row(&"language").pressed.emit()
	assert_eq(Settings.language, "vi")
	Settings.language = "xx"
	assert_eq(Settings.language, Settings.DEFAULT_LOCALE, "ngôn ngữ lạ về mặc định")


func test_settings_are_saved_and_loaded() -> void:
	Settings.sound_enabled = false
	Settings.music_enabled = false
	Settings.vibration_enabled = false
	Settings.water_quality = Ocean.Quality.LOW
	Settings.language = "en"
	Settings.tutorial_done = true
	assert_true(Settings.save(TEST_SAVE, true))
	# Đổi hết rồi nạp lại từ file.
	Settings.sound_enabled = true
	Settings.music_enabled = true
	Settings.vibration_enabled = true
	Settings.water_quality = Ocean.Quality.HIGH
	Settings.language = "vi"
	Settings.tutorial_done = false
	assert_true(Settings.load_saved(TEST_SAVE))
	assert_false(Settings.sound_enabled)
	assert_false(Settings.music_enabled)
	assert_false(Settings.vibration_enabled)
	assert_eq(Settings.water_quality, Ocean.Quality.LOW)
	assert_eq(Settings.language, "en")
	assert_true(Settings.tutorial_done)


func test_missing_or_broken_settings_keep_defaults() -> void:
	assert_false(Settings.load_saved("user://không_có_file.cfg"))
	var before: Dictionary = Settings.to_dictionary()
	Settings.apply_dictionary({ "sound": "linh tinh", "water_quality": 99, "language": 5 })
	assert_eq(Settings.water_quality, before["water_quality"], "mức nước lạ thì giữ nguyên")
	assert_eq(Settings.language, Settings.DEFAULT_LOCALE)


func test_no_saving_in_headless_runs() -> void:
	assert_false(Settings.persist, "test không ghi đè cài đặt thật của người chơi")
	assert_false(Settings.save(TEST_SAVE))


func test_result_and_pause_have_menu_buttons() -> void:
	var battle: BattleController = add_child_autofree(preload("res://battle/battle.tscn").instantiate())
	await wait_process_frames(2)
	battle.hud.show_result(false)
	await wait_process_frames(2)
	var menu: Button = battle.hud.result_panel.menu_button()
	assert_gte(menu.size.y, 120.0)
	assert_lt(menu.get_global_rect().get_center().x, _screen().size.x * 0.4, "Về menu ở góc dưới trái")
	assert_gt(menu.get_global_rect().get_center().y, _screen().size.y * 0.7)
	watch_signals(battle)
	menu.pressed.emit()
	assert_signal_emitted(battle, "menu_requested")
	battle.hud.result_panel.visible = false
	battle.hud.pause_menu.open("", PackedStringArray(), 1.0)
	await wait_process_frames(2)
	assert_true(_rect_in_screen(battle.hud.pause_menu.menu_button()))
	battle.hud.pause_menu.menu_button().pressed.emit()
	assert_signal_emit_count(battle, "menu_requested", 2)


func test_tutorial_walks_through_four_steps() -> void:
	Settings.tutorial_done = false
	var battle: BattleController = _boot.show_battle()
	await wait_process_frames(2)
	var hints: TutorialHints = battle.tutorial
	assert_not_null(hints, "chưa xem hướng dẫn thì có dải hướng dẫn")
	assert_eq(hints.step, TutorialHints.Step.PICK_PAD)
	assert_string_contains(hints.current_text(), "bệ")
	battle.hud.build_ring.open(Vector2(900, 500), battle.tower_choices, 200)
	await wait_process_frames(2)
	assert_eq(hints.step, TutorialHints.Step.BUILD)
	assert_string_contains(hints.current_text(), "dấu tích")
	var tower: Tower = battle.build_tower(battle.island.pads[4], load("res://data/towers/machine_gun.tres"))
	assert_eq(hints.step, TutorialHints.Step.ENEMY)
	assert_string_contains(hints.current_text(), "đèn đỏ")
	Events.wave_started.emit(0, 5)
	assert_eq(hints.step, TutorialHints.Step.MEGA)
	assert_false(hints.get_node("Hint").visible, "MEGA chỉ hiện khi có lô cốt đầy thanh")
	tower.overload.add_charge(1.0)
	assert_true(hints.get_node("Hint").visible)
	assert_string_contains(hints.current_text(), "MEGA")
	watch_signals(hints)
	battle.activate_mega(tower)
	assert_eq(hints.step, TutorialHints.Step.DONE)
	assert_true(Settings.tutorial_done)
	assert_signal_emitted(hints, "finished")


func test_tutorial_can_be_skipped_and_is_not_shown_again() -> void:
	Settings.tutorial_done = false
	var battle: BattleController = _boot.show_battle()
	await wait_process_frames(2)
	battle.tutorial.skip_button().pressed.emit()
	assert_false(battle.tutorial.is_active())
	assert_true(Settings.tutorial_done)
	_boot.return_to_menu()
	await wait_process_frames(2)
	var again: BattleController = _boot.show_battle()
	assert_null(again.tutorial, "đã xem rồi thì không hiện lại")


func test_title_side_buttons_fit_on_screen_without_overlap() -> void:
	var title: TitleScreen = TitleScreen.new()
	add_child_autofree(title)
	await wait_process_frames(2)
	var screen: Rect2 = title.get_viewport_rect()
	var settings: Rect2 = title.settings_button().get_global_rect()
	var base: Rect2 = title.base_button().get_global_rect()
	assert_true(screen.encloses(settings))
	assert_true(screen.encloses(base), "nút Căn cứ phải nằm trọn trong màn hình")
	assert_false(settings.intersects(base))
	assert_false(base.intersects(title.play_button().get_global_rect()))
