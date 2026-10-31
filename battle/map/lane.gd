class_name Lane
extends Path3D
## Một luồng địch. Dựng Curve3D mượt từ các điểm trong MapLayout và trả vị trí theo quãng đường đã đi.
## Vẽ một dải trên mặt nước, có vạch chạy về phía đảo để người chơi thấy hướng địch đi. Bình thường dải ẩn;
## chỉ hiện trong WARNING_SECONDS giây trước khi con địch đầu tiên của đợt ra ở luồng này, và tắt khi nó
## xuất hiện (góp ý 3 của đạo diễn). BattleController bật tắt qua set_warning().

const BAKE_INTERVAL: float = 0.5
## Độ cong ở mỗi điểm: tay nắm dài bằng tỉ lệ này của đoạn nối hai điểm kề bên.
const SMOOTHNESS: float = 0.25
const RIBBON_WIDTH: float = 2.4
## Cao hơn đỉnh sóng lớn nhất (khoảng 0,4) để sóng không xuyên qua dải.
const RIBBON_HEIGHT: float = 0.55
const RIBBON_STEP: float = 1.0
const RIBBON_SHADER: Shader = preload("res://battle/map/lane.gdshader")
## Luồng hiện trong chừng này giây trước khi địch đầu tiên của luồng xuất hiện.
const WARNING_SECONDS: float = 10.0
## Thời gian hiện dần và tắt dần, giây.
const FADE_IN_SECONDS: float = 0.4
const FADE_OUT_SECONDS: float = 0.8

var lane_index: int = -1
var name_key: StringName = &""

var _ribbon: MeshInstance3D
var _material: ShaderMaterial
var _strength: float = 0.0
var _warning: bool = false


## Dựng đường cong từ các điểm. Gọi được trước khi nút vào cây.
func setup(index: int, points: PackedVector3Array, lane_name_key: StringName) -> void:
	lane_index = index
	name_key = lane_name_key
	name = "Lane%d" % index
	curve = build_curve(points)
	_build_ribbon()


## Tổng chiều dài luồng, đơn vị Godot.
func length() -> float:
	return curve.get_baked_length() if curve != null else 0.0


## Vị trí trên luồng sau khi đi được quãng đường distance (kẹp trong [0, length]).
func position_at(distance: float) -> Vector3:
	return to_global_safe(curve.sample_baked(clampf(distance, 0.0, length()), true))


## Hướng đi (đã chuẩn hóa) tại quãng đường distance.
func direction_at(distance: float) -> Vector3:
	var total: float = length()
	var a: float = clampf(distance, 0.0, total)
	var b: float = minf(a + BAKE_INTERVAL, total)
	if is_equal_approx(a, b):
		a = maxf(b - BAKE_INTERVAL, 0.0)
	var dir: Vector3 = curve.sample_baked(b, true) - curve.sample_baked(a, true)
	return dir.normalized() if dir.length_squared() > 0.0 else Vector3.FORWARD


## Khoảng cách ngắn nhất (trên mặt phẳng nước) từ một điểm tới luồng.
func distance_to(point: Vector3) -> float:
	var local: Vector3 = point - global_position if is_inside_tree() else point - position
	var closest: Vector3 = curve.get_closest_point(local)
	return Vector2(closest.x - local.x, closest.z - local.z).length()


func to_global_safe(local: Vector3) -> Vector3:
	return to_global(local) if is_inside_tree() else local + position


static func build_curve(points: PackedVector3Array) -> Curve3D:
	var result: Curve3D = Curve3D.new()
	result.bake_interval = BAKE_INTERVAL
	var count: int = points.size()
	for i: int in count:
		var handle: Vector3 = Vector3.ZERO
		if i > 0 and i < count - 1:
			handle = (points[i + 1] - points[i - 1]) * SMOOTHNESS
		result.add_point(points[i], -handle, handle)
	return result


func _build_ribbon() -> void:
	if _ribbon != null:
		_ribbon.queue_free()
	var total: float = length()
	if total <= 0.0:
		return
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps: int = maxi(ceili(total / RIBBON_STEP), 1)
	var half: float = RIBBON_WIDTH * 0.5
	for i: int in steps + 1:
		var d: float = total * float(i) / float(steps)
		var center: Vector3 = curve.sample_baked(d, true)
		var forward: Vector3 = direction_at(d)
		var side: Vector3 = Vector3(-forward.z, 0.0, forward.x).normalized() * half
		center.y = RIBBON_HEIGHT
		# UV.x chạy ngang dải (0–1), UV.y là quãng đường còn lại tới đảo, để vạch chạy về phía đảo.
		st.set_uv(Vector2(0.0, total - d))
		st.add_vertex(center - side)
		st.set_uv(Vector2(1.0, total - d))
		st.add_vertex(center + side)
	for i: int in steps:
		var a: int = i * 2
		st.add_index(a)
		st.add_index(a + 2)
		st.add_index(a + 1)
		st.add_index(a + 1)
		st.add_index(a + 2)
		st.add_index(a + 3)
	_ribbon = MeshInstance3D.new()
	_ribbon.name = "Ribbon"
	_ribbon.mesh = st.commit()
	_ribbon.material_override = _ribbon_material()
	_ribbon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ribbon)
	_apply_strength()


## Bật hoặc tắt báo động: luồng hiện dần khi sắp có địch, tắt dần khi địch đã ra.
func set_warning(active: bool) -> void:
	_warning = active


func is_warning() -> bool:
	return _warning


## Độ rõ hiện tại của dải (0 = ẩn, 1 = rõ hẳn).
func strength() -> float:
	return _strength


func _process(delta: float) -> void:
	advance_fade(delta)


## Đưa độ rõ về phía đích (1 khi báo động, 0 khi không) sau delta giây.
func advance_fade(delta: float) -> void:
	var next: float = fade_toward(_strength, _warning, delta)
	if next == _strength:
		return
	_strength = next
	_apply_strength()


func _apply_strength() -> void:
	if _material != null:
		_material.set_shader_parameter(&"strength", _strength)
	if _ribbon != null:
		_ribbon.visible = _strength > 0.0


## Độ rõ sau delta giây: hiện dần trong FADE_IN_SECONDS, tắt dần trong FADE_OUT_SECONDS.
static func fade_toward(current: float, warning: bool, delta: float) -> float:
	if warning:
		return minf(current + delta / FADE_IN_SECONDS, 1.0)
	return maxf(current - delta / FADE_OUT_SECONDS, 0.0)


## Mỗi luồng một vật liệu để hiện rõ riêng từng luồng (4 luồng, vẫn chỉ 4 lệnh vẽ như trước).
func _ribbon_material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = RIBBON_SHADER
		_apply_strength()
	return _material
