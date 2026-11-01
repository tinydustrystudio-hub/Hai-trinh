class_name SettingsScreen
extends Control
## Màn Cài đặt (GDD mục 7.19, bản tháng 1): âm thanh, nhạc, rung, chất lượng nước, ngôn ngữ, hướng dẫn. Mỗi mục là một
## nút bật tắt lớn; đổi là có hiệu lực và được lưu ngay (Settings). Nút Quay lại ở góc dưới trái.

signal back_requested

const ROW_SIZE: Vector2 = Vector2(760, 130)

var _rows: Dictionary[StringName, Button] = {}
var _back: Button
var _title: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop: MenuBackdrop = MenuBackdrop.new()
	backdrop.name = "Backdrop"
	add_child(backdrop)
	var title: Label = UiStyle.label(UiStyle.TITLE_SIZE - 16)
	_title = title
	title.name = "Title"
	title.text = tr(&"SETTINGS_TITLE")
	title.add_theme_color_override(&"font_color", UiStyle.IVORY)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_SIZE, 60)
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(title)
	var card: PanelContainer = PanelContainer.new()
	card.name = "Card"
	card.add_theme_stylebox_override(&"panel", UiStyle.panel_box())
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	card.offset_top += 70
	add_child(card)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 20)
	grid.add_theme_constant_override(&"v_separation", 20)
	card.add_child(grid)
	for key: StringName in [&"sound", &"music", &"vibration", &"water", &"language", &"tutorial"]:
		var row: Button = UiStyle.primary_button(&"", Vector2(ROW_SIZE.x * 0.5, ROW_SIZE.y))
		row.name = String(key).capitalize()
		row.add_theme_font_size_override(&"font_size", 40)
		row.pressed.connect(_on_row_pressed.bind(key))
		grid.add_child(row)
		_rows[key] = row
	_back = UiStyle.secondary_button(&"BUTTON_BACK", Vector2(320, 140))
	_back.name = "Back"
	_back.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, UiStyle.MARGIN * 2)
	_back.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_back.pressed.connect(back_requested.emit)
	add_child(_back)
	refresh()


## Cập nhật chữ trên mọi nút theo cài đặt hiện tại.
func refresh() -> void:
	_title.text = tr(&"SETTINGS_TITLE")
	_back.text = tr(&"BUTTON_BACK")
	_rows[&"sound"].text = tr(&"PAUSE_SOUND_ON") if Settings.sound_enabled else tr(&"PAUSE_SOUND_OFF")
	_rows[&"music"].text = tr(&"PAUSE_MUSIC_ON") if Settings.music_enabled else tr(&"PAUSE_MUSIC_OFF")
	_rows[&"vibration"].text = tr(&"PAUSE_VIBRATION_ON") if Settings.vibration_enabled else tr(&"PAUSE_VIBRATION_OFF")
	_rows[&"water"].text = tr(&"DEBUG_WATER_HIGH") if Settings.water_quality == Ocean.Quality.HIGH else tr(&"DEBUG_WATER_LOW")
	_rows[&"language"].text = tr(&"SETTINGS_LANGUAGE_VI") if Settings.language == "vi" else tr(&"SETTINGS_LANGUAGE_EN")
	_rows[&"tutorial"].text = tr(&"SETTINGS_TUTORIAL_OFF") if Settings.tutorial_done else tr(&"SETTINGS_TUTORIAL_ON")


func row(key: StringName) -> Button:
	return _rows[key]


func back_button() -> Button:
	return _back


func _on_row_pressed(key: StringName) -> void:
	match key:
		&"sound":
			Settings.sound_enabled = not Settings.sound_enabled
		&"music":
			Settings.music_enabled = not Settings.music_enabled
		&"vibration":
			Settings.vibration_enabled = not Settings.vibration_enabled
		&"water":
			Settings.water_quality = Ocean.Quality.LOW if Settings.water_quality == Ocean.Quality.HIGH else Ocean.Quality.HIGH
		&"language":
			Settings.language = "en" if Settings.language == "vi" else "vi"
		&"tutorial":
			Settings.tutorial_done = not Settings.tutorial_done
	refresh()
