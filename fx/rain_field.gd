class_name RainField
extends MultiMeshInstance3D
## Mưa 3D (góp ý 8 của người duyệt: mưa phải rơi xuống biển và công trình, không phải một lớp phủ 2D trên màn hình):
## COUNT nét mưa thẳng đứng trong một khối không gian quanh điểm camera nhìn, một lệnh vẽ; mưa đứng yên trong không gian
## trận nên khi kéo camera, mưa trượt cùng sóng và công trình (không dính vào màn hình). Vị trí rơi tính hoàn toàn
## trong shader theo TIME nên không tốn CPU; mưa nhẹ chỉ hiện một phần số nét.

const SHADER: Shader = preload("res://fx/rain_field.gdshader")
const COUNT: int = 1600
## Khối mưa rộng theo x và z, đủ phủ vùng nhìn thấy khi thu nhỏ hết cỡ.
const AREA: Vector2 = Vector2(240.0, 170.0)
const FALL_HEIGHT: float = 16.0
const STREAK_WIDTH: float = 0.07
const STREAK_LENGTH: float = 1.5
## Gió (radian) đổi thành độ xiên của nét mưa.
const SLANT_PER_RADIAN: float = 0.5
const BASE_SLANT: float = 0.1

var rain: float = 0.0
## Điểm camera nhìn mà khối mưa đang phủ quanh.
var focus: Vector2 = Vector2.ZERO

var _material: ShaderMaterial


func _ready() -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(STREAK_WIDTH, STREAK_LENGTH)
	# QuadMesh nằm giữa gốc: dời lên để VERTEX.y chạy từ 0 (đầu nét) tới STREAK_LENGTH (đuôi nét); shader dùng VERTEX.y này.
	quad.center_offset = Vector3(0.0, STREAK_LENGTH * 0.5, 0.0)
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter(&"fall_height", FALL_HEIGHT)
	_material.set_shader_parameter(&"streak_length", STREAK_LENGTH)
	_material.set_shader_parameter(&"area", AREA)
	_material.render_priority = 3
	quad.material = _material
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 808
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = quad
	multimesh.instance_count = COUNT
	for i: int in COUNT:
		var at: Vector3 = Vector3(rng.randf_range(-AREA.x * 0.5, AREA.x * 0.5), 0.0, rng.randf_range(-AREA.y * 0.5, AREA.y * 0.5))
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, at))
		# Ngưỡng hiện rải đều 0–1: cường độ mưa x thì hiện đúng x phần số nét.
		multimesh.set_instance_custom_data(i, Color(rng.randf(), rng.randf(), float(i) / float(COUNT), 0.0))
	multimesh.custom_aabb = AABB(Vector3(-AREA.x * 0.5 - 20.0, -2.0, -AREA.y * 0.5 - 20.0), Vector3(AREA.x + 40.0, FALL_HEIGHT + 4.0, AREA.y + 40.0))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = false
	set_rain(rain, 0.0)


## Cường độ mưa (0–1) và góc gió (radian).
func set_rain(intensity: float, wind: float) -> void:
	rain = intensity
	if _material == null:
		return
	visible = intensity > 0.01
	_material.set_shader_parameter(&"intensity", intensity)
	_material.set_shader_parameter(&"slant", Vector2(BASE_SLANT + wind * SLANT_PER_RADIAN, 0.0))


## Cho khối mưa phủ quanh điểm camera nhìn mà mưa vẫn đứng yên trong không gian trận: node không dời, hạt nào ra khỏi
## khối thì xuất hiện lại ở mép đối diện (tính trong shader).
func follow(center: Vector2) -> void:
	focus = center
	if _material != null:
		_material.set_shader_parameter(&"focus", center)


func is_showing() -> bool:
	return visible


## Số nét mưa đang hiện: cường độ nhân tổng số.
func streaks_shown() -> int:
	return int(floor(rain * float(COUNT)))
