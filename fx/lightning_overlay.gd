class_name LightningOverlay
extends CanvasLayer
## Sét (góp ý 4, mục 12): chớp sáng trắng xanh phủ màn hình hai nhịp và một tia sét ngoằn ngoèo từ trời xuống mặt biển,
## tắt trong chưa đầy nửa giây. Dựng bằng một Line2D tái dùng, không tạo node mới mỗi lần.

const FLASH_SECONDS: float = 0.5
const BOLT_SEGMENTS: int = 9
const BOLT_COLOR: Color = Color(0.86, 0.92, 1.0)

var strikes: int = 0

var _flash: ColorRect
var _bolt: Line2D
var _glow: Line2D
var _tween: Tween
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	layer = 2
	_rng.seed = 99
	_flash = ColorRect.new()
	_flash.name = "Flash"
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(0.85, 0.92, 1.0, 1.0)
	_flash.modulate.a = 0.0
	add_child(_flash)
	_glow = _make_line("Glow", 22.0, Color(0.6, 0.75, 1.0, 0.35))
	_bolt = _make_line("Bolt", 6.0, BOLT_COLOR)


## Đánh một tia sét ở vị trí ngang x_ratio (0–1) của màn hình.
func strike(x_ratio: float) -> void:
	strikes += 1
	var size: Vector2 = get_viewport().get_visible_rect().size
	var points: PackedVector2Array = bolt_points(_rng, size, x_ratio)
	_bolt.points = points
	_glow.points = points
	_bolt.modulate.a = 1.0
	_glow.modulate.a = 1.0
	if _tween != null:
		_tween.kill()
	_flash.modulate.a = 0.0
	_tween = create_tween()
	_tween.set_parallel(false)
	_tween.tween_property(_flash, "modulate:a", 0.55, 0.04)
	_tween.tween_property(_flash, "modulate:a", 0.1, 0.07)
	_tween.tween_property(_flash, "modulate:a", 0.4, 0.04)
	_tween.tween_property(_flash, "modulate:a", 0.0, FLASH_SECONDS - 0.15)
	_tween.parallel().tween_property(_bolt, "modulate:a", 0.0, FLASH_SECONDS - 0.15)
	_tween.parallel().tween_property(_glow, "modulate:a", 0.0, FLASH_SECONDS - 0.15)


## Các đỉnh của tia sét: từ đỉnh màn hình xuống khoảng 55–75% chiều cao, lệch ngang ngẫu nhiên mỗi đoạn.
static func bolt_points(rng: RandomNumberGenerator, size: Vector2, x_ratio: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var bottom: float = size.y * rng.randf_range(0.55, 0.75)
	var x: float = size.x * clampf(x_ratio, 0.0, 1.0)
	for i: int in BOLT_SEGMENTS + 1:
		var y: float = bottom * float(i) / float(BOLT_SEGMENTS)
		points.append(Vector2(x, y))
		x += rng.randf_range(-70.0, 70.0)
	return points


func _make_line(node_name: String, width: float, color: Color) -> Line2D:
	var line: Line2D = Line2D.new()
	line.name = node_name
	line.width = width
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.modulate.a = 0.0
	add_child(line)
	return line
