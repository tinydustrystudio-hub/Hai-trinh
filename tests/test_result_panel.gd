extends GutTest
## Màn kết quả: chữ đúng, nút Chơi lại từ 120 px và nằm trọn ở góc dưới bên phải (GDD mục 7.1, 7.12).

const PANEL_SCENE: PackedScene = preload("res://ui/result_panel.tscn")

var _panel: ResultPanel


func before_each() -> void:
	TranslationServer.set_locale("vi")
	var layer: CanvasLayer = add_child_autofree(CanvasLayer.new())
	_panel = PANEL_SCENE.instantiate()
	layer.add_child(_panel)


func test_titles() -> void:
	_panel.show_result(true)
	assert_eq(_panel.title_text(), "Chiến thắng")
	_panel.show_result(false)
	assert_eq(_panel.title_text(), "Đảo đã chìm")


func test_retry_button_in_bottom_right_corner() -> void:
	_panel.show_result(false)
	await wait_process_frames(2)
	var screen: Rect2 = _panel.get_viewport_rect()
	var rect: Rect2 = _panel.retry_button().get_global_rect()
	assert_gte(rect.size.x, 120.0)
	assert_gte(rect.size.y, 120.0)
	assert_true(screen.encloses(rect), "nút phải nằm trọn trong màn hình: %s trong %s" % [rect, screen])
	assert_gt(rect.get_center().x, screen.size.x * 0.5)
	assert_gt(rect.get_center().y, screen.size.y * 0.5)


func test_retry_emits() -> void:
	watch_signals(_panel)
	_panel.retry_button().pressed.emit()
	assert_signal_emitted(_panel, "retry_requested")
