class_name MenuBackdrop
extends Control
## Nền chung của các màn menu (P2): biển sâu chuyển sắc từ xanh đậm lên xanh biển, vài lớp sóng trôi chậm và hình
## pháo đài lục giác của Liên Minh Mũi Neo mờ ở một bên. Vẽ hoàn toàn bằng code, không cần ảnh.

const TOP: Color = Color(0.02, 0.07, 0.15)
const BOTTOM: Color = Color(0.05, 0.2, 0.34)
const LAYERS: int = 4

var _time: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var bands: int = 24
	for i: int in bands:
		var t: float = float(i) / float(bands - 1)
		draw_rect(Rect2(0.0, size.y * float(i) / float(bands), size.x, size.y / float(bands) + 1.0), TOP.lerp(BOTTOM, t))
	_draw_fortress(Vector2(size.x * 0.72, size.y * 0.5), minf(size.x, size.y) * 0.34)
	for layer: int in LAYERS:
		_draw_wave_line(rect, layer)


## Pháo đài lục giác mờ: hai vành và sáu mỏm bến, viền ngà và cam rất nhạt.
func _draw_fortress(center: Vector2, radius: float) -> void:
	var ivory: Color = Color(UiStyle.IVORY, 0.16)
	var orange: Color = Color(UiStyle.RESCUE_ORANGE, 0.22)
	for ring: int in 3:
		var r: float = radius * (1.0 - 0.28 * float(ring))
		var points: PackedVector2Array = PackedVector2Array()
		for k: int in 7:
			var a: float = deg_to_rad(60.0 * float(k) + 30.0 * float(ring % 2))
			points.append(center + Vector2(cos(a), sin(a)) * r)
		draw_polyline(points, orange if ring == 0 else ivory, 6.0 - float(ring), true)
	for k: int in 6:
		var a: float = deg_to_rad(60.0 * float(k) + 30.0)
		var tip: Vector2 = center + Vector2(cos(a), sin(a)) * radius * 1.3
		draw_line(center + Vector2(cos(a), sin(a)) * radius * 0.95, tip, ivory, 10.0, true)
		draw_arc(tip, radius * 0.08, 0.0, TAU, 24, orange, 4.0, true)
	draw_circle(center, radius * 0.1, Color(UiStyle.GOLD, 0.35))
	draw_arc(center, radius * 0.16, 0.0, TAU, 32, ivory, 4.0, true)


func _draw_wave_line(rect: Rect2, layer: int) -> void:
	var base: float = rect.size.y * (0.6 + 0.1 * float(layer))
	var amplitude: float = 10.0 + 6.0 * float(layer)
	var speed: float = 0.25 + 0.1 * float(layer)
	var points: PackedVector2Array = PackedVector2Array()
	var steps: int = 48
	for i: int in steps + 1:
		var x: float = rect.size.x * float(i) / float(steps)
		var y: float = base + sin(x * 0.006 * (1.0 + 0.3 * float(layer)) + _time * speed * 3.0 + float(layer) * 2.0) * amplitude
		points.append(Vector2(x, y))
	draw_polyline(points, Color(0.6, 0.8, 0.95, 0.12 + 0.04 * float(layer)), 3.0, true)
