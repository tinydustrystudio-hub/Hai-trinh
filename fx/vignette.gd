class_name Vignette
extends CanvasLayer
## Tối viền màn hình (P6): một ColorRect phủ toàn màn, nằm dưới giao diện (layer 0). Tắt ở chất lượng thấp.

const SHADER: Shader = preload("res://fx/vignette.gdshader")

var _rect: ColorRect
var _material: ShaderMaterial
var strength: float = 0.0


func _ready() -> void:
	layer = 0
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_rect = ColorRect.new()
	_rect.name = "Rect"
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.material = _material
	add_child(_rect)
	set_look(strength, Color(0, 0.03, 0.08))


func set_look(amount: float, tint: Color) -> void:
	strength = clampf(amount, 0.0, 1.0)
	if _material != null:
		_material.set_shader_parameter(&"strength", strength)
		_material.set_shader_parameter(&"tint", tint)
	if _rect != null:
		_rect.visible = strength > 0.001


## Bật hoặc tắt (chất lượng thấp tắt để tiết kiệm lượt vẽ toàn màn hình).
func set_enabled(on: bool) -> void:
	visible = on
