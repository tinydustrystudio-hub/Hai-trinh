class_name CoinIcon
extends Control
## Biểu tượng Tiền Vàng vẽ bằng code (không cần ảnh): đồng xu vàng viền sẫm, vành trong, mỏ neo đơn giản ở giữa
## (dấu hiệu Liên Minh Mũi Neo) và một vệt sáng. Dùng ở HUD và mọi nơi hiện giá.

const SIZE: float = 48.0


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.5 - 2.0
	draw_circle(c + Vector2(0, 2), r, Color(0, 0, 0, 0.35))
	draw_circle(c, r, UiStyle.GOLD_DARK)
	draw_circle(c, r * 0.88, UiStyle.GOLD)
	draw_arc(c, r * 0.68, 0.0, TAU, 32, UiStyle.GOLD_DARK, 2.0, true)
	# Mỏ neo: thân dọc, thanh ngang, hai cánh cong ở đáy.
	var anchor: Color = UiStyle.GOLD_DARK.darkened(0.15)
	draw_line(c + Vector2(0, -r * 0.4), c + Vector2(0, r * 0.38), anchor, 3.0, true)
	draw_line(c + Vector2(-r * 0.2, -r * 0.2), c + Vector2(r * 0.2, -r * 0.2), anchor, 3.0, true)
	draw_arc(c + Vector2(0, r * 0.06), r * 0.34, deg_to_rad(20.0), deg_to_rad(160.0), 12, anchor, 3.0, true)
	draw_circle(c + Vector2(0, -r * 0.46), r * 0.08, anchor)
	# Vệt sáng trên trái.
	draw_arc(c, r * 0.8, deg_to_rad(200.0), deg_to_rad(250.0), 8, Color(1, 1, 1, 0.55), 3.0, true)
