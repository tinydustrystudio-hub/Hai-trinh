class_name RainOverlay
extends CanvasLayer
## Màn mưa (góp ý 4, mục 12): một hình chữ nhật phủ màn hình chạy rain_overlay.gdshader, nằm dưới giao diện.
## Mưa xiên theo hướng gió; không có mưa thì ẩn hẳn để không tốn lượt vẽ.

const SHADER: Shader = preload("res://fx/rain_overlay.gdshader")
## Gió (radian) đổi thành độ xiên của vệt mưa.
const SLANT_PER_RADIAN: float = 0.35

var _rect: ColorRect
var _material: ShaderMaterial
var rain: float = 0.0


func _ready() -> void:
	layer = 0
	_rect = ColorRect.new()
	_rect.name = "Rain"
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_rect.material = _material
	_rect.visible = false
	add_child(_rect)


func set_rain(intensity: float, wind: float) -> void:
	rain = intensity
	if _rect == null:
		return
	_rect.visible = intensity > 0.01
	_material.set_shader_parameter(&"intensity", intensity)
	_material.set_shader_parameter(&"slant", 0.12 + wind * SLANT_PER_RADIAN)
	var size: Vector2 = get_viewport().get_visible_rect().size
	_material.set_shader_parameter(&"aspect", size.x / maxf(size.y, 1.0))


func is_showing() -> bool:
	return _rect != null and _rect.visible
