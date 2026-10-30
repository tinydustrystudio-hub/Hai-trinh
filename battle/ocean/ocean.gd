class_name Ocean
extends MeshInstance3D
## Mặt nước: một mặt phẳng chia ô chạy water.gdshader. Hai mức chất lượng theo kế hoạch tháng 1:
## cao = 128×128 ô với 3 lớp sóng, thấp = 64×64 ô với 2 lớp.
## height_at() tính lại sóng trên CPU (cùng công thức với shader) để tàu nổi theo sóng.

enum Quality { LOW, HIGH }

const SIZE: float = 320.0
const SUBDIVISIONS: Dictionary[Quality, int] = { Quality.LOW: 63, Quality.HIGH: 127 }
const WAVE_COUNTS: Dictionary[Quality, int] = { Quality.LOW: 2, Quality.HIGH: 3 }
const WATER_SHADER: Shader = preload("res://battle/ocean/water.gdshader")
const GRAVITY: float = 9.8

## Mỗi sóng: x, y = hướng; z = độ dốc; w = bước sóng (đơn vị Godot).
@export var waves: Array[Vector4] = [
	Vector4(1.0, 0.4, 0.10, 22.0),
	Vector4(-0.3, 1.0, 0.08, 13.0),
	Vector4(0.7, -0.6, 0.06, 7.0),
]

var quality: Quality = Quality.HIGH

var _material: ShaderMaterial


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = WATER_SHADER
	_material.set_shader_parameter(&"wave_a", waves[0])
	_material.set_shader_parameter(&"wave_b", waves[1])
	_material.set_shader_parameter(&"wave_c", waves[2])
	_material.set_shader_parameter(&"gravity", GRAVITY)
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	set_quality(Settings.water_quality)


func set_quality(value: Quality) -> void:
	quality = value
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(SIZE, SIZE)
	plane.subdivide_width = SUBDIVISIONS[value]
	plane.subdivide_depth = SUBDIVISIONS[value]
	mesh = plane
	if _material != null:
		_material.set_shader_parameter(&"wave_count", wave_count())


func wave_count() -> int:
	return mini(WAVE_COUNTS[quality], waves.size())


## Độ cao mặt nước tại (x, z) ở thời điểm time (giây, cùng đồng hồ TIME của shader).
## Bỏ qua phần dịch ngang của sóng Gerstner: đủ chính xác cho việc nhấp nhô tàu.
func height_at(x: float, z: float, time: float) -> float:
	return wave_height(waves, wave_count(), x, z, time)


static func wave_height(wave_list: Array[Vector4], count: int, x: float, z: float, time: float) -> float:
	var h: float = 0.0
	for i: int in mini(count, wave_list.size()):
		var w: Vector4 = wave_list[i]
		var k: float = TAU / w.w
		var c: float = sqrt(GRAVITY / k)
		var d: Vector2 = Vector2(w.x, w.y).normalized()
		h += (w.z / k) * sin(k * (d.x * x + d.y * z - c * time))
	return h
