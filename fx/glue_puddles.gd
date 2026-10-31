class_name GluePuddles
extends MultiMeshInstance3D
## Vẽ mọi vũng keo bằng một MultiMesh (một lệnh vẽ). Mỗi nhịp: begin(), các Lô Cốt Keo gọi draw(),
## rồi finish(). Màu từng vũng mang độ mờ theo thời gian còn lại.

const MAX_PUDDLES: int = 64
const PUDDLE_Y: float = 0.24
const SHADER: Shader = preload("res://fx/glue_puddle.gdshader")

var _used: int = 0


func _ready() -> void:
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(2.0, 2.0)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"noise_tex", Ocean.foam_noise())
	material.render_priority = -1
	plane.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = plane
	multimesh.instance_count = MAX_PUDDLES
	multimesh.visible_instance_count = 0
	multimesh.custom_aabb = AABB(Vector3(-500, -10, -500), Vector3(1000, 20, 1000))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func begin() -> void:
	_used = 0


## Một vũng keo tâm center, bán kính radius, còn life (0–1) thời gian.
func draw(center: Vector3, radius: float, life: float) -> void:
	if _used >= MAX_PUDDLES:
		return
	var xform: Transform3D = Transform3D(Basis.IDENTITY.scaled(Vector3(radius, 1.0, radius)), Vector3(center.x, PUDDLE_Y, center.z))
	multimesh.set_instance_transform(_used, xform)
	multimesh.set_instance_color(_used, Color(1.0, 1.0, 1.0, clampf(life, 0.0, 1.0)))
	_used += 1


func finish() -> void:
	multimesh.visible_instance_count = _used


func count() -> int:
	return _used
