class_name ResultPanel
extends Control
## Màn kết quả đơn giản của tháng 1: "Chiến thắng" hoặc "Đảo đã chìm", nút Chơi lại ở góc dưới phải.

signal retry_requested

var _title: Label
var _panel: PanelContainer
var _retry: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	_panel = PanelContainer.new()
	_panel.name = "Card"
	_panel.add_theme_stylebox_override(&"panel", UiStyle.panel_box())
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_panel)
	_title = UiStyle.label(UiStyle.TITLE_SIZE)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.custom_minimum_size = Vector2(900, 220)
	_panel.add_child(_title)
	_retry = UiStyle.primary_button(&"BUTTON_RETRY")
	_retry.name = "Retry"
	_retry.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, UiStyle.MARGIN * 2)
	# Nút lớn ra theo chữ thì lớn về phía trong màn hình.
	_retry.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_retry.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_retry.pressed.connect(retry_requested.emit)
	add_child(_retry)
	visible = false


func show_result(won: bool) -> void:
	_title.text = tr(&"RESULT_WIN") if won else tr(&"RESULT_LOSE")
	# Thắng thì chữ vàng ấm, thua thì chữ ngà.
	_title.add_theme_color_override(&"font_color", UiStyle.GOLD.lightened(0.3) if won else UiStyle.IVORY)
	visible = true


func retry_button() -> Button:
	return _retry


func card() -> PanelContainer:
	return _panel


func title_text() -> String:
	return _title.text
