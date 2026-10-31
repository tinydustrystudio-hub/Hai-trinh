extends GutTest
## Nền giao diện (P1 kế hoạch hoàn thiện): bảng màu Liên Minh Mũi Neo, nút nổi khối ≥ 120 px, tiếng bấm,
## đồng Tiền Vàng ở HUD, chuyển cảnh mờ dần, thẻ kết quả.

const BATTLE_SCENE: PackedScene = preload("res://battle/battle.tscn")


func test_palette_matches_concept_pack() -> void:
	assert_eq(UiStyle.SEA_BLUE.to_html(false).to_upper(), "1F5F8B")
	assert_eq(UiStyle.IVORY.to_html(false).to_upper(), "EDE6D6")
	assert_eq(UiStyle.RESCUE_ORANGE.to_html(false).to_upper(), "FF7A1A")
	assert_eq(UiStyle.GRAPHITE.to_html(false).to_upper(), "3A4048")
	assert_eq(UiStyle.PRIMARY, UiStyle.RESCUE_ORANGE, "nút chính là cam cứu hộ")


func test_buttons_are_big_and_raised() -> void:
	for button: Button in [UiStyle.primary_button(&"BUTTON_RETRY"), UiStyle.secondary_button(&"BUTTON_BACK")]:
		assert_gte(button.custom_minimum_size.x, 120.0)
		assert_gte(button.custom_minimum_size.y, 120.0)
		var normal: StyleBoxFlat = button.get_theme_stylebox(&"normal") as StyleBoxFlat
		var pushed: StyleBoxFlat = button.get_theme_stylebox(&"pressed") as StyleBoxFlat
		assert_gt(normal.border_width_bottom, normal.border_width_top, "mép dưới dày hơn: nổi khối")
		assert_lt(pushed.border_width_bottom, normal.border_width_bottom, "bấm xuống thì mép dưới mỏng đi")
		assert_gt(pushed.content_margin_top, normal.content_margin_top, "chữ hạ xuống khi bấm")
		button.free()


func test_disabled_button_is_grey() -> void:
	var button: Button = UiStyle.primary_button(&"BUTTON_RETRY")
	var box: StyleBoxFlat = button.get_theme_stylebox(&"disabled") as StyleBoxFlat
	assert_eq(box.bg_color, UiStyle.DISABLED)
	button.free()


func test_button_press_emits_click() -> void:
	watch_signals(Events)
	var button: Button = UiStyle.primary_button(&"BUTTON_RETRY")
	button.pressed.emit()
	assert_signal_emit_count(Events, "ui_clicked", 1)
	button.free()


func test_click_sound_plays_and_is_gentle() -> void:
	var board: SoundBoard = add_child_autofree(SoundBoard.new())
	var wav: AudioStreamWAV = board.stream(SoundBoard.Sound.CLICK)
	assert_almost_eq(wav.get_length(), 0.09, 0.01)
	Events.ui_clicked.emit()
	assert_eq(board.played[SoundBoard.Sound.CLICK], 1)
	assert_lt(SoundBoard.VOLUME_DB[SoundBoard.Sound.CLICK], SoundBoard.VOLUME_DB[SoundBoard.Sound.EXPLOSION])


func test_panel_has_ivory_border() -> void:
	var box: StyleBoxFlat = UiStyle.panel_box()
	assert_gt(box.border_width_top, 0)
	assert_gt(box.border_color.get_luminance(), 0.5)


func test_hud_shows_gold_coin_and_number() -> void:
	TranslationServer.set_locale("vi")
	var battle: BattleController = add_child_autofree(BATTLE_SCENE.instantiate())
	var coin: CoinIcon = battle.hud.find_child("GoldCoin", true, false) as CoinIcon
	assert_not_null(coin, "đồng xu cạnh số Tiền Vàng")
	assert_gte(coin.custom_minimum_size.x, 40.0)
	assert_eq(battle.hud.steel_text(), "200")
	assert_eq(battle.economy.steel, 200, "đổi tên hiển thị, không đổi cơ chế")


func test_gold_name_in_debug_button() -> void:
	TranslationServer.set_locale("vi")
	assert_string_contains(tr(&"DEBUG_ADD_STEEL"), "Tiền Vàng")
	TranslationServer.set_locale("en")
	assert_string_contains(tr(&"DEBUG_ADD_STEEL"), "Gold")
	TranslationServer.set_locale("vi")


func test_screen_fade_runs_both_ways() -> void:
	var fade: ScreenFade = add_child_autofree(ScreenFade.new())
	assert_eq(fade.cover(), 0.0)
	fade.fade_out(0.0)
	assert_eq(fade.cover(), 1.0)
	fade.fade_in(0.0)
	assert_eq(fade.cover(), 0.0)
	fade.fade_in(0.2)
	assert_eq(fade.cover(), 1.0, "bắt đầu từ tối")


func test_battle_fades_in_on_start() -> void:
	var battle: BattleController = add_child_autofree(BATTLE_SCENE.instantiate())
	assert_not_null(battle.fade)
	assert_gt(battle.fade.cover(), 0.0, "vào trận từ màn tối")


func test_result_card_is_a_panel_and_keeps_retry_bottom_right() -> void:
	var battle: BattleController = add_child_autofree(BATTLE_SCENE.instantiate())
	battle.hud.show_result(true)
	await wait_process_frames(2)
	var panel: ResultPanel = battle.hud.result_panel
	assert_not_null(panel.card())
	var card: Rect2 = panel.card().get_global_rect()
	assert_lt(absf(card.get_center().x - 960.0), 40.0, "thẻ ở giữa màn hình")
	var retry: Rect2 = panel.retry_button().get_global_rect()
	assert_gt(retry.get_center().x, 960.0)
	assert_gt(retry.get_center().y, 540.0)
