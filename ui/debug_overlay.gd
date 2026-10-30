class_name DebugOverlay
extends CanvasLayer
## Bảng debug (kế hoạch mục 7): khung/giây, mili giây mỗi khung, số địch, lệnh vẽ, tam giác,
## chất lượng nước, thời gian vào trận; nút sinh 60 địch và nút đổi chất lượng nước.
## Chỉ có trong bản debug, hoặc bản web mở với ?debug (hay ?stress cho cảnh thử 60 địch).

const REFRESH_SECONDS: float = 0.25
const LOG_SECONDS: float = 2.0
const BURST_SIZE: int = 60

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
	column.add_theme_constant_override(&"separation", 16)
	_panel.add_child(column)
	_stats = UiStyle.label(32)
	column.add_child(_stats)
	var burst: Button = UiStyle.primary_button(&"DEBUG_SPAWN_60", Vector2(420, 120))
	burst.name = "Burst"
	burst.pressed.connect(_on_burst_pressed)
	column.add_child(burst)
	_water = UiStyle.primary_button(&"", Vector2(420, 120))
	_water.name = "Water"
	_water.pressed.connect(_on_water_pressed)
	column.add_child(_water)
	expanded = expanded
	_refresh()


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


func _on_burst_pressed() -> void:
	var battle: BattleController = owner as BattleController
	if battle != null:
		battle.spawn_burst(BURST_SIZE)


func _on_water_pressed() -> void:
	Settings.water_quality = Ocean.Quality.LOW if Settings.water_quality == Ocean.Quality.HIGH else Ocean.Quality.HIGH
	_refresh()
