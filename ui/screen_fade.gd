class_name ScreenFade
extends CanvasLayer
## Chuyển cảnh mờ dần (P1 của kế hoạch hoàn thiện): tấm tối phủ màn hình, tối dần hoặc sáng dần trong DURATION giây.
## Nằm trên cùng, không chặn chạm khi đã trong suốt.

const DURATION: float = 0.45
const COLOR: Color = Color(0.01, 0.05, 0.1)

var _rect: ColorRect
var _tween: Tween


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.name = "Cover"
	_rect.color = COLOR
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.modulate.a = 0.0
	add_child(_rect)


## Từ tối sáng dần lên (vào màn).
func fade_in(seconds: float = DURATION) -> void:
	_run(1.0, 0.0, seconds)


## Từ trong suốt tối dần (rời màn).
func fade_out(seconds: float = DURATION) -> void:
	_run(0.0, 1.0, seconds)


## Độ che hiện tại (0 trong suốt, 1 tối hẳn).
func cover() -> float:
	return _rect.modulate.a if _rect != null else 0.0


func _run(from: float, to: float, seconds: float) -> void:
	if _tween != null:
		_tween.kill()
	_rect.modulate.a = from
	if seconds <= 0.0:
		_rect.modulate.a = to
		return
	_tween = create_tween()
	_tween.set_ignore_time_scale(true)
	_tween.tween_property(_rect, "modulate:a", to, seconds)
