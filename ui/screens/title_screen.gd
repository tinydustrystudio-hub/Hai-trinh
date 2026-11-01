class_name TitleScreen
extends Control
## Màn tiêu đề (GDD mục 7.3): tên game lớn, câu giới thiệu, nút Ra khơi ở góc dưới phải (hành động chính), nút Cài đặt
## ở góc dưới trái, số phiên bản. Nút tối thiểu 120 px.

signal play_requested
signal settings_requested

const PLAY_SIZE: Vector2 = Vector2(480, 170)
const SETTINGS_SIZE: Vector2 = Vector2(360, 140)

var _play: Button
var _settings: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop: MenuBackdrop = MenuBackdrop.new()
	backdrop.name = "Backdrop"
	add_child(backdrop)
	var title: Label = UiStyle.label(UiStyle.TITLE_SIZE + 60)
	title.name = "Title"
	title.text = tr(&"GAME_TITLE")
	title.add_theme_color_override(&"font_color", UiStyle.IVORY)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.position = Vector2(UiStyle.MARGIN * 3, 250)
	add_child(title)
	var tagline: Label = UiStyle.label(UiStyle.TEXT_SIZE + 4)
	tagline.name = "Tagline"
	tagline.text = tr(&"TITLE_TAGLINE")
	tagline.add_theme_color_override(&"font_color", UiStyle.GOLD.lightened(0.3))
	tagline.position = Vector2(UiStyle.MARGIN * 3, 450)
	add_child(tagline)
	_play = UiStyle.primary_button(&"TITLE_PLAY", PLAY_SIZE)
	_play.name = "Play"
	_play.add_theme_font_size_override(&"font_size", 64)
	_play.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, UiStyle.MARGIN * 2)
	_play.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_play.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_play.pressed.connect(play_requested.emit)
	add_child(_play)
	_settings = UiStyle.secondary_button(&"TITLE_SETTINGS", SETTINGS_SIZE)
	_settings.name = "Settings"
	_settings.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, UiStyle.MARGIN * 2)
	_settings.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_settings.pressed.connect(settings_requested.emit)
	add_child(_settings)
	var version: Label = UiStyle.label(26)
	version.name = "Version"
	var number: String = str(ProjectSettings.get_setting("application/config/version", ""))
	version.text = "v%s" % (number if not number.is_empty() else "0.1")
	version.modulate = Color(1, 1, 1, 0.55)
	version.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, UiStyle.MARGIN)
	version.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(version)


func play_button() -> Button:
	return _play


func settings_button() -> Button:
	return _settings
