class_name ResultPanel
extends Control
## Màn kết quả đơn giản của tháng 1: "Chiến thắng" hoặc "Đảo đã chìm", nút Chơi lại ở góc dưới phải.

signal retry_requested

var _title: Label
var _retry: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	_title = UiStyle.label(UiStyle.TITLE_SIZE)
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_title)
	_retry = UiStyle.primary_button(&"BUTTON_RETRY")
	_retry.name = "Retry"
	_retry.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, UiStyle.MARGIN * 2)
	_retry.pressed.connect(retry_requested.emit)
	add_child(_retry)
	visible = false


func show_result(won: bool) -> void:
	_title.text = tr(&"RESULT_WIN") if won else tr(&"RESULT_LOSE")
	visible = true


func title_text() -> String:
	return _title.text
