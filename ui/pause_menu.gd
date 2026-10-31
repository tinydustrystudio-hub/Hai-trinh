class_name PauseMenu
extends Control
## Màn Tạm dừng (GDD mục 7.11): trái là mục tiêu của màn; giữa là nút Tiếp tục cỡ lớn, Chơi lại và cài đặt
## nhanh (âm thanh, nhạc nền, tốc độ, rung); phải là thẻ các địch đã gặp; dưới phải là Tiếp tục.
## Tháng 1 chưa có bản đồ thế giới nên chưa có nút Thoát ra bản đồ ở dưới trái.

signal resume_requested
signal restart_requested
signal speed_toggled

const BIG_BUTTON: Vector2 = Vector2(520, 160)
const BUTTON: Vector2 = Vector2(360, 130)
const QUICK_BUTTON: Vector2 = Vector2(280, 130)

var _resume_big: Button
var _restart: Button
var _sound: Button
var _music: Button
var _speed: Button
var _vibration: Button
var _resume_corner: Button
var _objective: Label
var _enemies: Label
var _speed_value: float = 1.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.0, 0.03, 0.08, 0.86)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var title: Label = UiStyle.label(UiStyle.TITLE_SIZE - 16)
	title.text = &"PAUSE_TITLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_SIZE, 70)
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(title)
	var center: VBoxContainer = VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override(&"separation", 24)
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(center)
	_resume_big = UiStyle.primary_button(&"BUTTON_RESUME", BIG_BUTTON)
	_resume_big.add_theme_font_size_override(&"font_size", 60)
	_resume_big.pressed.connect(resume_requested.emit)
	center.add_child(_resume_big)
	_restart = UiStyle.primary_button(&"BUTTON_RESTART", BIG_BUTTON)
	_restart.pressed.connect(restart_requested.emit)
	center.add_child(_restart)
	var quick: HBoxContainer = HBoxContainer.new()
	quick.add_theme_constant_override(&"separation", 16)
	quick.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(quick)
	_sound = UiStyle.primary_button(&"", QUICK_BUTTON)
	_sound.add_theme_font_size_override(&"font_size", 34)
	_sound.pressed.connect(_on_sound_pressed)
	quick.add_child(_sound)
	_music = UiStyle.primary_button(&"", QUICK_BUTTON)
	_music.add_theme_font_size_override(&"font_size", 34)
	_music.pressed.connect(_on_music_pressed)
	quick.add_child(_music)
	_speed = UiStyle.primary_button(&"", QUICK_BUTTON)
	_speed.add_theme_font_size_override(&"font_size", 34)
	_speed.pressed.connect(speed_toggled.emit)
	quick.add_child(_speed)
	_vibration = UiStyle.primary_button(&"", QUICK_BUTTON)
	_vibration.add_theme_font_size_override(&"font_size", 34)
	_vibration.pressed.connect(_on_vibration_pressed)
	quick.add_child(_vibration)
	_objective = UiStyle.label(34)
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD
	_objective.custom_minimum_size = Vector2(380, 0)
	_objective.position = Vector2(UiStyle.MARGIN * 2, 260)
	add_child(_objective)
	_enemies = UiStyle.label(30)
	_enemies.autowrap_mode = TextServer.AUTOWRAP_WORD
	_enemies.custom_minimum_size = Vector2(420, 0)
	_enemies.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, UiStyle.MARGIN * 2)
	_enemies.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_enemies.offset_top = 260
	add_child(_enemies)
	_resume_corner = UiStyle.primary_button(&"BUTTON_RESUME", BUTTON)
	_resume_corner.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, UiStyle.MARGIN * 2)
	_resume_corner.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_resume_corner.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_resume_corner.pressed.connect(resume_requested.emit)
	add_child(_resume_corner)
	visible = false


## Mở màn tạm dừng; objective là mục tiêu của màn, enemies là tên các loại địch đã gặp.
func open(objective: String, enemies: PackedStringArray, speed: float) -> void:
	_objective.text = objective
	_enemies.text = "%s\n%s" % [tr(&"PAUSE_ENEMIES"), "\n".join(enemies)] if not enemies.is_empty() else ""
	refresh(speed)
	visible = true


func close() -> void:
	visible = false


func is_open() -> bool:
	return visible


func refresh(speed: float) -> void:
	_speed_value = speed
	_sound.text = tr(&"PAUSE_SOUND_ON") if Settings.sound_enabled else tr(&"PAUSE_SOUND_OFF")
	_music.text = tr(&"PAUSE_MUSIC_ON") if Settings.music_enabled else tr(&"PAUSE_MUSIC_OFF")
	_vibration.text = tr(&"PAUSE_VIBRATION_ON") if Settings.vibration_enabled else tr(&"PAUSE_VIBRATION_OFF")
	_speed.text = tr(&"HUD_SPEED_FAST") if speed > 1.0 else tr(&"HUD_SPEED_NORMAL")


func buttons() -> Array[Button]:
	return [_resume_big, _restart, _sound, _music, _speed, _vibration, _resume_corner]


func resume_corner_button() -> Button:
	return _resume_corner


func resume_big_button() -> Button:
	return _resume_big


func _on_sound_pressed() -> void:
	Settings.sound_enabled = not Settings.sound_enabled
	refresh(_speed_value)


func _on_music_pressed() -> void:
	Settings.music_enabled = not Settings.music_enabled
	refresh(_speed_value)


func _on_vibration_pressed() -> void:
	Settings.vibration_enabled = not Settings.vibration_enabled
	refresh(_speed_value)
