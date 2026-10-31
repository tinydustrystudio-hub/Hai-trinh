class_name BulletRenderer
extends MultiMeshInstance3D
## Vẽ mọi vệt đạn bằng một MultiMesh (một lệnh vẽ). Mỗi vệt là một thanh sáng mảnh từ đầu nòng tới
## điểm trúng, sống LIFETIME giây rồi tắt. Mảng cấp phát một lần; vệt mới ghi đè vệt cũ nhất khi đầy.

const MAX_TRACERS: int = 192
const LIFETIME: float = 0.07
const THICKNESS: float = 0.12
const COLOR: Color = Color(1.0, 0.9, 0.45)

var _starts: PackedVector3Array = PackedVector3Array()
var _ends: PackedVector3Array = PackedVector3Array()
var _life: PackedFloat32Array = PackedFloat32Array()
var _next: int = 0
var _alive: int = 0


func _ready() -> void:
	_starts.resize(MAX_TRACERS)
	_ends.resize(MAX_TRACERS)
	_life.resize(MAX_TRACERS)
	_life.fill(0.0)
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3.ONE
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = COLOR
	box.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = box
	multimesh.instance_count = MAX_TRACERS
	multimesh.visible_instance_count = 0
	multimesh.custom_aabb = AABB(Vector3(-500, -10, -500), Vector3(1000, 40, 1000))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func add_tracer(from: Vector3, to: Vector3) -> void:
	if _life.is_empty():
		return
	if _life[_next] <= 0.0:
		_alive += 1
	_starts[_next] = from
	_ends[_next] = to
	_life[_next] = LIFETIME
	_next = (_next + 1) % MAX_TRACERS


## Số vệt đang hiện.
func active_count() -> int:
	return _alive


## Một nhịp: giảm tuổi, ghi các vệt còn sống vào MultiMesh.
func advance(delta: float) -> void:
	var used: int = 0
	_alive = 0
	for i: int in _life.size():
		if _life[i] <= 0.0:
			continue
		_life[i] -= delta
		if _life[i] <= 0.0:
			continue
		_alive += 1
		var a: Vector3 = _starts[i]
		var b: Vector3 = _ends[i]
		var span: Vector3 = b - a
		var length: float = span.length()
		if length < 0.01:
			continue
		var up: Vector3 = Vector3.UP if absf(span.normalized().y) < 0.99 else Vector3.RIGHT
		var basis: Basis = Basis.looking_at(span / length, up).scaled_local(Vector3(THICKNESS, THICKNESS, length))
		multimesh.set_instance_transform(used, Transform3D(basis, (a + b) * 0.5))
		used += 1
	multimesh.visible_instance_count = used
