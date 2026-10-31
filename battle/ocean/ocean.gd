class_name Ocean
extends MeshInstance3D
## Mặt nước: một mặt phẳng chia ô chạy water.gdshader (nước bản 2, GDD mục 8.6). Hai mức chất lượng:
## cao = 192×192 ô, 6 lớp sóng, hai lớp normal map, mây phản chiếu và lấp lánh; thấp = 96×96 ô, 3 lớp sóng lớn,
## một lớp normal map, mây phản chiếu một lớp.
## Sóng sinh ngẫu nhiên theo hạt giống (góp ý 3 của đạo diễn): mỗi lớp lệch hướng gió một góc, bước sóng lẻ nhau,
## biên độ nhấp nhô dọc theo ngọn sóng, nên mặt biển không còn những vệt chéo đều tăm tắp.
## height_at() tính lại sóng trên CPU (cùng công thức với shader) để tàu nổi theo sóng.

enum Quality { LOW, HIGH }

const SIZE: float = 440.0
const SUBDIVISIONS: Dictionary[Quality, int] = { Quality.LOW: 95, Quality.HIGH: 191 }
const WAVE_COUNTS: Dictionary[Quality, int] = { Quality.LOW: 3, Quality.HIGH: 6 }
## Số lớp sóng tối đa (cùng cỡ mảng trong water.gdshader).
const MAX_WAVES: int = 6
const WAVE_SEED: int = 20261031
## Bước sóng gốc của từng lớp (đơn vị Godot), mỗi lớp lệch ngẫu nhiên ±15%.
const BASE_WAVELENGTHS: Array[float] = [34.0, 23.0, 16.5, 13.0, 10.5, 9.0]
## Các lớp lệch hướng gió tối đa chừng này (radian).
const DIRECTION_SPREAD: float = 1.15
## Độ cao lớn nhất khi mọi lớp cùng lên đỉnh (thấp hơn dải luồng 0,55): sóng nhẹ.
const MAX_WAVE_HEIGHT: float = 0.34
const WATER_SHADER: Shader = preload("res://battle/ocean/water.gdshader")
const GRAVITY: float = 9.8
const NORMAL_MAP_SIZE: int = 256
## Vệt sáng của nước, tính theo bán kính đảo chính: cách tâm đảo, bề ngang, bề sâu.
const HIGHLIGHT_DISTANCE: float = 2.4
const HIGHLIGHT_WIDTH: float = 2.2
const HIGHLIGHT_DEPTH: float = 1.3

## Mỗi sóng: x, y = hướng; z = độ dốc; w = bước sóng (đơn vị Godot).
var waves: Array[Vector4] = []
## Nhấp nhô biên độ của từng sóng dọc theo ngọn: x = pha, y = tỉ lệ tần số so với sóng, z = tốc độ, w = độ sâu.
var shapes: Array[Vector4] = []

static var _normal_a: NoiseTexture2D
static var _normal_b: NoiseTexture2D
static var _foam_noise: NoiseTexture2D

var quality: Quality = Quality.HIGH

var _material: ShaderMaterial


func _init() -> void:
	var generated: Array = make_waves(WAVE_SEED)
	waves = generated[0]
	shapes = generated[1]


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = WATER_SHADER
	_material.set_shader_parameter(&"waves", PackedVector4Array(waves))
	_material.set_shader_parameter(&"wave_shapes", PackedVector4Array(shapes))
	_material.set_shader_parameter(&"gravity", GRAVITY)
	_material.set_shader_parameter(&"normal_a", _normal_map(0))
	_material.set_shader_parameter(&"normal_b", _normal_map(1))
	_material.set_shader_parameter(&"cloud_tex", foam_noise())
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
	return wave_height(waves, wave_count(), x, z, time, shapes)


## Tổng độ cao các sóng. shape_list (tùy chọn) làm biên độ từng sóng nhấp nhô dọc theo ngọn sóng.
static func wave_height(wave_list: Array[Vector4], count: int, x: float, z: float, time: float, shape_list: Array[Vector4] = []) -> float:
	var h: float = 0.0
	for i: int in mini(count, wave_list.size()):
		var w: Vector4 = wave_list[i]
		var k: float = TAU / w.w
		var c: float = sqrt(GRAVITY / k)
		var d: Vector2 = Vector2(w.x, w.y).normalized()
		var amplitude: float = w.z / k
		if i < shape_list.size():
			amplitude *= crest_modulation(shape_list[i], d, k, x, z, time)
		h += amplitude * sin(k * (d.x * x + d.y * z - c * time))
	return h


## Hệ số biên độ của một sóng tại (x, z): đổi dần dọc theo ngọn sóng và trôi chậm theo thời gian.
static func crest_modulation(shape: Vector4, direction: Vector2, k: float, x: float, z: float, time: float) -> float:
	var along: float = -direction.y * x + direction.x * z
	return 1.0 + shape.w * sin(along * k * shape.y + time * shape.z + shape.x)


## Sinh các lớp sóng từ hạt giống: một hướng gió chung, mỗi lớp lệch hướng và bước sóng ngẫu nhiên.
## Độ dốc chia sao cho mọi lớp cùng lên đỉnh cũng chỉ cao MAX_WAVE_HEIGHT. Trả về [waves, shapes].
static func make_waves(wave_seed: int) -> Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = wave_seed
	var wind: float = rng.randf() * TAU
	var result_waves: Array[Vector4] = []
	var result_shapes: Array[Vector4] = []
	var peak: float = 0.0
	for i: int in MAX_WAVES:
		var angle: float = wind + rng.randf_range(-DIRECTION_SPREAD, DIRECTION_SPREAD)
		var wavelength: float = BASE_WAVELENGTHS[i] * rng.randf_range(0.85, 1.15)
		# Lớp dài dốc hơn một chút; lớp ngắn thoải hơn.
		var steepness: float = lerpf(1.0, 0.6, float(i) / float(MAX_WAVES - 1))
		var shape: Vector4 = Vector4(rng.randf() * TAU, rng.randf_range(0.18, 0.4), rng.randf_range(0.15, 0.35), rng.randf_range(0.3, 0.55))
		result_waves.append(Vector4(cos(angle), sin(angle), steepness, wavelength))
		result_shapes.append(shape)
		peak += steepness * wavelength / TAU * (1.0 + shape.w)
	var scale: float = MAX_WAVE_HEIGHT / peak
	for i: int in MAX_WAVES:
		result_waves[i].z *= scale
	return [result_waves, result_shapes]


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
