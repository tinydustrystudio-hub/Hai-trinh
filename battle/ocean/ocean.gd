class_name Ocean
extends MeshInstance3D
## Mặt nước: một mặt phẳng chia ô chạy water.gdshader (nước bản 2, GDD mục 8.6). Hai mức chất lượng:
## cao = 128×128 ô, 3 lớp sóng, hai lớp normal map và lấp lánh; thấp = 64×64 ô, 2 lớp sóng, một lớp normal map
## (vẫn giữ vệt sáng mềm sau đảo).
## height_at() tính lại sóng trên CPU (cùng công thức với shader) để tàu nổi theo sóng.

enum Quality { LOW, HIGH }

const SIZE: float = 440.0
const SUBDIVISIONS: Dictionary[Quality, int] = { Quality.LOW: 63, Quality.HIGH: 127 }
const WAVE_COUNTS: Dictionary[Quality, int] = { Quality.LOW: 2, Quality.HIGH: 3 }
const WATER_SHADER: Shader = preload("res://battle/ocean/water.gdshader")
const GRAVITY: float = 9.8
const NORMAL_MAP_SIZE: int = 256
## Vệt sáng của nước, tính theo bán kính đảo chính: cách tâm đảo, bề ngang, bề sâu.
const HIGHLIGHT_DISTANCE: float = 2.4
const HIGHLIGHT_WIDTH: float = 2.2
const HIGHLIGHT_DEPTH: float = 1.3

## Mỗi sóng: x, y = hướng; z = độ dốc; w = bước sóng (đơn vị Godot). Sóng nhẹ: cao nhất khoảng 0,25.
@export var waves: Array[Vector4] = [
	Vector4(1.0, 0.4, 0.04, 24.0),
	Vector4(-0.3, 1.0, 0.03, 14.0),
	Vector4(0.7, -0.6, 0.025, 8.0),
]

static var _normal_a: NoiseTexture2D
static var _normal_b: NoiseTexture2D
static var _foam_noise: NoiseTexture2D

var quality: Quality = Quality.HIGH

var _material: ShaderMaterial


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = WATER_SHADER
	_material.set_shader_parameter(&"wave_a", waves[0])
	_material.set_shader_parameter(&"wave_b", waves[1])
	_material.set_shader_parameter(&"wave_c", waves[2])
	_material.set_shader_parameter(&"gravity", GRAVITY)
	_material.set_shader_parameter(&"normal_a", _normal_map(0))
	_material.set_shader_parameter(&"normal_b", _normal_map(1))
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	set_quality(Settings.water_quality)
	Settings.water_quality_changed.connect(set_quality)


## Màu nắng, vùng nước sáng quanh đảo chính và vệt sáng phía sau đảo theo hướng nhìn của camera
## (view_forward: hướng nhìn của camera trên mặt nước). Không dùng hướng nắng chiếu công trình.
func configure(sun_color: Color, island_center: Vector3, island_radius: float, view_forward: Vector3) -> void:
	if _material == null:
		return
	_material.set_shader_parameter(&"sun_color", sun_color)
	_material.set_shader_parameter(&"island_glow", Vector4(island_center.x, island_center.z, island_radius, island_radius * 0.7))
	var center: Vector2 = highlight_center(island_center, island_radius, view_forward)
	_material.set_shader_parameter(&"highlight_center", center)
	_material.set_shader_parameter(&"highlight_size", Vector2(island_radius * HIGHLIGHT_WIDTH, island_radius * HIGHLIGHT_DEPTH))


## Tâm vệt sáng của nước: sau đảo chính, theo hướng nhìn của camera.
static func highlight_center(island_center: Vector3, island_radius: float, view_forward: Vector3) -> Vector2:
	var forward: Vector2 = Vector2(view_forward.x, view_forward.z)
	forward = forward.normalized() if forward.length() > 0.001 else Vector2(0.0, -1.0)
	return Vector2(island_center.x, island_center.z) + forward * island_radius * HIGHLIGHT_DISTANCE


func set_quality(value: Quality) -> void:
	quality = value
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(SIZE, SIZE)
	plane.subdivide_width = SUBDIVISIONS[value]
	plane.subdivide_depth = SUBDIVISIONS[value]
	mesh = plane
	if _material != null:
		_material.set_shader_parameter(&"wave_count", wave_count())
		_material.set_shader_parameter(&"detail", 1 if value == Quality.HIGH else 0)


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


## Nhiễu liền mạch dùng chung cho bọt (quanh đảo, sau đuôi tàu).
static func foam_noise() -> NoiseTexture2D:
	if _foam_noise == null:
		_foam_noise = _noise_texture(7, 0.03, false)
	return _foam_noise


## Hai normal map cuộn, dựng bằng nhiễu lúc chạy (không cần file ảnh).
static func _normal_map(index: int) -> NoiseTexture2D:
	if index == 0:
		if _normal_a == null:
			_normal_a = _noise_texture(11, 0.018, true)
		return _normal_a
	if _normal_b == null:
		_normal_b = _noise_texture(23, 0.04, true)
	return _normal_b


static func _noise_texture(noise_seed: int, frequency: float, as_normal: bool) -> NoiseTexture2D:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = frequency
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_octaves = 3
	var texture: NoiseTexture2D = NoiseTexture2D.new()
	texture.width = NORMAL_MAP_SIZE
	texture.height = NORMAL_MAP_SIZE
	texture.seamless = true
	texture.noise = noise
	texture.as_normal_map = as_normal
	texture.bump_strength = 6.0
	texture.generate_mipmaps = true
	return texture
