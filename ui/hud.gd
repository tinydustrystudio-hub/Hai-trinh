class_name Hud
extends CanvasLayer
## HUD trận theo GDD mục 7.10, mọi thứ nằm trong vùng an toàn (tránh tai thỏ):
## - trên trái: Độ Nổi (thanh và số), đợt hiện tại / tổng số đợt;
## - trên giữa: báo đợt sắp tới (giây còn lại, tầng địch); hướng địch tới do đèn báo trên đảo chính chỉ;
## - trên phải: Tiền Vàng (đồng xu và số), nút ×1/×2, nút Tạm dừng;
## - dưới trái: Gọi đợt sớm khi đang chờ đợt kế;
## - MEGA: chạm thẳng lô cốt đang nhấp nháy hào quang (khay nút MEGA ở góc dưới phải đã ẩn).
## Kèm vòng chọn lô cốt, vòng nâng cấp, thẻ chọn nhánh, màn Tạm dừng và màn kết quả.
## Chỉ nghe Events; lệnh gửi về BattleController qua tín hiệu.

signal retry_requested
signal pause_requested
signal resume_requested
signal speed_toggled
signal call_wave_requested
signal menu_requested

const TOP_BUTTON: Vector2 = Vector2(128, 128)
const CALL_BUTTON: Vector2 = Vector2(320, 130)

## Khung theo vùng an toàn; các góc neo vào khung này.
var frame: Control

var _buoyancy: BuoyancyBar
var _wave: Label
var _incoming: Label
var _steel: Label
var _speed: Button
var _pause: Button
var _call_wave: Button

@onready var result_panel: ResultPanel = $ResultPanel
@onready var build_ring: BuildRing = $BuildRing
@onready var upgrade_ring: UpgradeRing = $UpgradeRing
@onready var branch_cards: BranchCards = $BranchCards
@onready var mega_tray: MegaTray = $MegaTray
@onready var pause_menu: PauseMenu = $PauseMenu


func _ready() -> void:
	frame = Control.new()
	frame.name = "Frame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(frame)
	move_child(frame, 0)
	_build_top_left()
	_build_top_center()
	_build_top_right()
	_build_bottom_left()
	mega_tray.reparent(frame)
	# MEGA kích bằng cách chạm vào lô cốt đang nhấp nháy (người duyệt 1/11); khay nút ở góc dưới phải không dùng nữa.
	mega_tray.visible = false
	apply_safe_area()
	get_viewport().size_changed.connect(apply_safe_area)
	result_panel.retry_requested.connect(retry_requested.emit)
	result_panel.menu_requested.connect(menu_requested.emit)
	pause_menu.menu_requested.connect(menu_requested.emit)
	pause_menu.resume_requested.connect(resume_requested.emit)
	pause_menu.restart_requested.connect(retry_requested.emit)
	pause_menu.speed_toggled.connect(speed_toggled.emit)
	Events.steel_changed.connect(_on_steel_changed)
	Events.buoyancy_changed.connect(_on_buoyancy_changed)
	Events.wave_started.connect(_on_wave_started)
	Events.wave_incoming.connect(_on_wave_incoming)
	Events.wave_cleared.connect(_on_wave_cleared)


## Thu khung vào vùng an toàn của màn hình (tai thỏ, góc bo, thanh điều hướng).
func apply_safe_area() -> void:
	var insets: Vector4 = safe_insets()
	frame.offset_left = insets.x
	frame.offset_top = insets.y
	frame.offset_right = -insets.z
	frame.offset_bottom = -insets.w


## Lề an toàn (trái, trên, phải, dưới) theo đơn vị của khung hình trận.
func safe_insets() -> Vector4:
	var window: Vector2 = Vector2(DisplayServer.window_get_size())
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	if window.x <= 0.0 or window.y <= 0.0 or DisplayServer.get_name() == "headless":
		return Vector4.ZERO
	var safe: Rect2 = Rect2(DisplayServer.get_display_safe_area())
	var screen: Vector2 = Vector2(DisplayServer.screen_get_size())
	if safe.size.x <= 0.0 or screen != window:
		# Chỉ áp dụng khi chạy toàn màn hình (điện thoại); cửa sổ và trình duyệt máy tính không có tai thỏ.
		return Vector4.ZERO
	var scale: Vector2 = viewport / window
	return Vector4(safe.position.x * scale.x, safe.position.y * scale.y,
		(window.x - safe.end.x) * scale.x, (window.y - safe.end.y) * scale.y)


func show_result(won: bool) -> void:
	_incoming.text = ""
	_call_wave.visible = false
	pause_menu.close()
	result_panel.show_result(won)


func hide_result() -> void:
	result_panel.visible = false
	_wave.text = ""
	_incoming.text = ""


func show_pause(objective: String, enemies: PackedStringArray, speed: float) -> void:
	pause_menu.open(objective, enemies, speed)


func hide_pause() -> void:
	pause_menu.close()


func set_speed_label(speed: float) -> void:
	_speed.text = tr(&"HUD_SPEED_FAST") if speed > 1.0 else tr(&"HUD_SPEED_NORMAL")
	pause_menu.refresh(speed)


func buoyancy_text() -> String:
	return _buoyancy.text()


func wave_text() -> String:
	return _wave.text


func steel_text() -> String:
	return _steel.text


func incoming_text() -> String:
	return _incoming.text


func pause_button() -> Button:
	return _pause


func speed_button() -> Button:
	return _speed


func call_wave_button() -> Button:
	return _call_wave


func _build_top_left() -> void:
	var column: VBoxContainer = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.position = Vector2(UiStyle.MARGIN, UiStyle.MARGIN)
	column.add_theme_constant_override(&"separation", 8)
	frame.add_child(column)
	_buoyancy = BuoyancyBar.new()
	column.add_child(_buoyancy)
	_wave = UiStyle.label()
	column.add_child(_wave)


func _build_top_center() -> void:
	_incoming = UiStyle.label()
	_incoming.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_incoming.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_SIZE, UiStyle.MARGIN)
	_incoming.grow_horizontal = Control.GROW_DIRECTION_BOTH
	frame.add_child(_incoming)


func _build_top_right() -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_END
	frame.add_child(row)
	var coin: CoinIcon = CoinIcon.new()
	coin.name = "GoldCoin"
	coin.custom_minimum_size = Vector2(CoinIcon.SIZE + 8.0, CoinIcon.SIZE + 8.0)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(coin)
	_steel = UiStyle.label(UiStyle.TEXT_SIZE + 8)
	_steel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_steel.add_theme_color_override(&"font_color", UiStyle.GOLD.lightened(0.35))
	row.add_child(_steel)
	_speed = UiStyle.primary_button(&"HUD_SPEED_NORMAL", TOP_BUTTON)
	_speed.name = "Speed"
	_speed.pressed.connect(speed_toggled.emit)
	row.add_child(_speed)
	_pause = UiStyle.primary_button(&"HUD_PAUSE", TOP_BUTTON)
	_pause.name = "Pause"
	_pause.pressed.connect(pause_requested.emit)
	row.add_child(_pause)
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, UiStyle.MARGIN)
	row.grow_horizontal = Control.GROW_DIRECTION_BEGIN


func _build_bottom_left() -> void:
	_call_wave = UiStyle.primary_button(&"HUD_CALL_WAVE", CALL_BUTTON)
	_call_wave.name = "CallWave"
	_call_wave.add_theme_font_size_override(&"font_size", 38)
	_call_wave.pressed.connect(call_wave_requested.emit)
	_call_wave.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, UiStyle.MARGIN * 2)
	_call_wave.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_call_wave.visible = false
	frame.add_child(_call_wave)


func _on_steel_changed(value: int) -> void:
	_steel.text = tr(&"HUD_STEEL") % value
	build_ring.set_steel(value)
	upgrade_ring.set_steel(value)


func _on_buoyancy_changed(value: int, max_value: int) -> void:
	_buoyancy.set_value(value, max_value)


func _on_wave_started(index: int, total: int) -> void:
	_wave.text = tr(&"HUD_WAVE") % [index + 1, total]
	_incoming.text = ""
	_call_wave.visible = false


func _on_wave_cleared(_index: int) -> void:
	_incoming.text = ""


func _on_wave_incoming(index: int, _lane_indices: PackedInt32Array, seconds: float) -> void:
	var battle: BattleController = owner as BattleController
	var layers: PackedStringArray = PackedStringArray()
	if battle != null:
		layers = battle.layer_names_in_wave(index)
	_incoming.text = tr(&"HUD_NEXT_WAVE") % [index + 1, ceili(seconds)]
	if not layers.is_empty():
		_incoming.text += "\n" + " · ".join(layers)
	_call_wave.visible = battle != null and not battle.is_over() and not battle.stress_mode
