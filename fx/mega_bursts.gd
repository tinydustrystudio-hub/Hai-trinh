class_name MegaBursts
extends MultiMeshInstance3D
## Hiệu ứng kích MEGA (tạm, kế hoạch mục 4): vòng sáng cam bung ra trong DURATION giây.
## Tối đa MAX_FULL vòng đầy đủ cùng lúc (rộng bằng tầm lô cốt, sáng mạnh); từ vòng thứ ba trở đi
## dùng bản nhẹ (nhỏ, mờ). Vẽ chung một MultiMesh, mảng cấp phát một lần.

const DURATION: float = 0.5
const MAX_FULL: int = 2
const MAX_BURSTS: int = 12
const LIGHT_RADIUS: float = 4.0
const SHADER: Shader = preload("res://fx/mega_burst.gdshader")

var _centers: PackedVector3Array = PackedVector3Array()
var _radius: PackedFloat32Array = PackedFloat32Array()
var _age: PackedFloat32Array = PackedFloat32Array()
var _full: PackedByteArray = PackedByteArray()


func _ready() -> void:
	_centers.resize(MAX_BURSTS)
	_radius.resize(MAX_BURSTS)
	_age.resize(MAX_BURSTS)
	_age.fill(DURATION)
	_full.resize(MAX_BURSTS)
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(2.0, 2.0)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	plane.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = plane
	multimesh.instance_count = MAX_BURSTS
	multimesh.visible_instance_count = 0
	multimesh.custom_aabb = AABB(Vector3(-500, -10, -500), Vector3(1000, 40, 1000))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Bung một vòng tại center, rộng tới radius; đã đủ MAX_FULL vòng đầy đủ thì dùng bản nhẹ.
## Trả true nếu là vòng đầy đủ.
func spawn(center: Vector3, radius: float) -> bool:
	var slot: int = -1
	for i: int in MAX_BURSTS:
		if _age[i] >= DURATION:
			slot = i
			break
	if slot == -1:
		return false
	var full: bool = full_count() < MAX_FULL
	_centers[slot] = Vector3(center.x, 0.3, center.z)
	_radius[slot] = radius if full else LIGHT_RADIUS
	_age[slot] = 0.0
	_full[slot] = 1 if full else 0
	return full


## Số vòng đầy đủ đang hiện.
func full_count() -> int:
	var count: int = 0
	for i: int in MAX_BURSTS:
		if _age[i] < DURATION and _full[i] == 1:
			count += 1
	return count


func active_count() -> int:
	var count: int = 0
	for i: int in MAX_BURSTS:
		if _age[i] < DURATION:
			count += 1
	return count


func advance(delta: float) -> void:
	var used: int = 0
	for i: int in MAX_BURSTS:
		if _age[i] >= DURATION:
			continue
		_age[i] += delta
		if _age[i] >= DURATION:
			continue
		var t: float = _age[i] / DURATION
		var r: float = maxf(_radius[i] * (0.2 + 0.8 * t), 0.01)
		multimesh.set_instance_transform(used, Transform3D(Basis.IDENTITY.scaled(Vector3(r, 1.0, r)), _centers[i]))
		# r = tiến độ, g = đầy đủ (1) hay nhẹ (0).
		multimesh.set_instance_color(used, Color(t, float(_full[i]), 0.0, 1.0))
		used += 1
	multimesh.visible_instance_count = used
