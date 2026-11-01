class_name DebugOverlay
extends CanvasLayer
## Bảng debug (kế hoạch mục 7): khung/giây, mili giây mỗi khung, số địch, lệnh vẽ, tam giác,
## chất lượng nước, thời gian vào trận; nút sinh 60 địch, nút đổi chất lượng nước và nút thêm Thép
## (để thử nâng cấp và nhánh cấp 5 cho nhanh).
## Chỉ có trong bản debug, hoặc bản web mở với ?debug (hay ?stress cho cảnh thử 60 địch).

const REFRESH_SECONDS: float = 0.25
const LOG_SECONDS: float = 2.0
const BURST_SIZE: int = 60
const STEEL_GIFT: int = 500

## Ghi số đo ra console mỗi LOG_SECONDS (cảnh thử dùng để đọc số từ trình duyệt hoặc logcat).
var log_to_console: bool = false
var expanded: bool = false:
	set(value):
		expanded = value
		if _panel != null:
			_panel.visible = value

var _panel: PanelContainer
var _stats: Label
var _water: Button
var _weather: Button
var _light: Button
var _difficulty: Button
var _refresh_left: float = 0.0
var _log_left: float = LOG_SECONDS
var _last_usec: int = 0


func _ready() -> void:
	layer = 20
	if not Settings.debug_tools_enabled():
		queue_free()
		return
	var toggle: Button = UiStyle.primary_button(&"DEBUG_TOGGLE", UiStyle.MIN_BUTTON)
	toggle.name = "Toggle"
	toggle.add_theme_font_size_override(&"font_size", 32)
	toggle.modulate = Color(1, 1, 1, 0.7)
	toggle.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_MINSIZE, UiStyle.MARGIN)
	toggle.pressed.connect(func() -> void: expanded = not expanded)
	add_child(toggle)
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.add_theme_stylebox_override(&"panel", UiStyle.panel_box())
	_panel.position = Vector2(UiStyle.MARGIN * 2 + UiStyle.MIN_BUTTON.x, 200)
	add_child(_panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	_panel.add_child(column)
	_stats = UiStyle.label(32)
	column.add_child(_stats)
	# Nút xếp hai cột để bảng không dài quá màn hình điện thoại.
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 12)
	grid.add_theme_constant_override(&"v_separation", 12)
	column.add_child(grid)
	var burst: Button = _debug_button(&"DEBUG_SPAWN_60", grid)
	burst.name = "Burst"
	burst.pressed.connect(_on_burst_pressed)
	var gift: Button = _debug_button(&"DEBUG_ADD_STEEL", grid)
	gift.name = "Steel"
	gift.pressed.connect(_on_steel_pressed)
	_water = _debug_button(&"", grid)
	_water.name = "Water"
	_water.pressed.connect(_on_water_pressed)
	_weather = _debug_button(&"", grid)
	_weather.name = "Weather"
	_weather.pressed.connect(_on_weather_pressed)
	_light = _debug_button(&"", grid)
	_light.name = "Light"
	_light.pressed.connect(_on_light_pressed)
	_difficulty = _debug_button(&"", grid)
	_difficulty.name = "Difficulty"
	_difficulty.pressed.connect(_on_difficulty_pressed)
	expanded = expanded
	_refresh()


func _debug_button(text_key: StringName, parent: Control) -> Button:
	var button: Button = UiStyle.primary_button(text_key, Vector2(300, 120))
	button.add_theme_font_size_override(&"font_size", 30)
	parent.add_child(button)
	return button


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	var real_delta: float = 0.0 if _last_usec == 0 else float(now - _last_usec) / 1_000_000.0
	_last_usec = now
	_refresh_left -= real_delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		_refresh()
	if log_to_console:
		_log_left -= real_delta
		if _log_left <= 0.0:
			_log_left = LOG_SECONDS
			print(perf_line(snapshot()))


## Số đo hiện tại.
func snapshot() -> Dictionary:
	var battle: BattleController = owner as BattleController
	if battle != null and not battle.is_node_ready():
		battle = null
	var fps: float = Engine.get_frames_per_second()
	return {
		"fps": fps,
		"frame_ms": 1000.0 / fps if fps > 0.0 else 0.0,
		"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"enemies": battle.enemy_pool.active_count() if battle != null else 0,
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"water": "high" if Settings.water_quality == Ocean.Quality.HIGH else "low",
		"ready_ms": battle.ready_msec if battle != null else 0,
	}


## Một dòng số đo cho console, dễ lọc bằng tiền tố PERF.
static func perf_line(s: Dictionary) -> String:
	return "PERF fps=%d frame_ms=%.1f process_ms=%.1f enemies=%d draw_calls=%d primitives=%d water=%s ready_ms=%d" % [
		roundi(s["fps"]), s["frame_ms"], s["process_ms"], s["enemies"], s["draw_calls"], s["primitives"], s["water"], s["ready_ms"]]


func _refresh() -> void:
	if _stats == null:
		return
	var s: Dictionary = snapshot()
	_stats.text = tr(&"DEBUG_STATS") % [roundi(s["fps"]), s["frame_ms"], s["process_ms"], s["enemies"],
		s["draw_calls"], s["primitives"], s["ready_ms"]]
	_water.text = tr(&"DEBUG_WATER_HIGH") if Settings.water_quality == Ocean.Quality.HIGH else tr(&"DEBUG_WATER_LOW")
	var battle: BattleController = owner as BattleController
	if battle != null and battle.is_node_ready() and battle.weather != null:
		_weather.text = tr(&"DEBUG_WEATHER") % tr(battle.weather.data.name_key)
	_difficulty.text = tr(&"DEBUG_DIFFICULTY") % tr(Difficulty.name_key(Profile.difficulty))
	if battle != null and battle.is_node_ready() and battle.lighting != null:
		_light.text = tr(&"DEBUG_LIGHT") % tr(battle.lighting.name_key)


func _on_burst_pressed() -> void:
	var battle: BattleController = owner as BattleController
	if battle != null:
		battle.spawn_burst(BURST_SIZE)


func _on_steel_pressed() -> void:
	var battle: BattleController = owner as BattleController
	if battle != null:
		battle.economy.earn(STEEL_GIFT)


func _on_water_pressed() -> void:
	Settings.water_quality = Ocean.Quality.LOW if Settings.water_quality == Ocean.Quality.HIGH else Ocean.Quality.HIGH
	_refresh()


## Bình thường → mưa → bão → bình thường.
## Ban ngày → bình minh → hoàng hôn → ban ngày.
func _on_light_pressed() -> void:
	var battle: BattleController = owner as BattleController
	if battle == null or battle.lighting == null:
		return
	var next: int = (Lighting.ORDER.find(battle.lighting.id) + 1) % Lighting.ORDER.size()
	battle.set_lighting(Lighting.ORDER[next])
	_refresh()


## Dễ → Trung bình → Khó → Dễ; đổi số đảo mua thêm dùng được nên chơi lại màn.
func _on_difficulty_pressed() -> void:
	Profile.set_difficulty(Difficulty.next(Profile.difficulty))
	var battle: BattleController = owner as BattleController
	if battle != null:
		battle.retry()
	_refresh()


func _on_weather_pressed() -> void:
	var battle: BattleController = owner as BattleController
	if battle == null or battle.weather == null:
		return
	var order: Array[StringName] = [&"clear", &"rain", &"storm"]
	var next: int = (order.find(battle.weather.data.id) + 1) % order.size()
	battle.set_weather(order[next])
	_refresh()
