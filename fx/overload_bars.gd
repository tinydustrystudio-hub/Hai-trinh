class_name OverloadBars
extends MultiMeshInstance3D
## Thanh Quá tải nổi trên đầu mọi lô cốt, một MultiMesh (một lệnh vẽ). Màu theo trạng thái:
## đang nạp cam nhạt; sẵn sàng cam sáng nhấp nháy; MEGA trắng nóng; làm mát xanh lạnh.

const MAX_TOWERS: int = 16
const WIDTH: float = 3.4
const HEIGHT: float = 0.5
const LIFT: float = 3.4
const BAR_SHADER: Shader = preload("res://fx/bar.gdshader")
const CHARGING: Color = Color(1.0, 0.6, 0.25)
const READY: Color = Color(1.0, 0.5, 0.05)
const MEGA: Color = Color(1.0, 0.95, 0.75)
const COOLDOWN: Color = Color(0.45, 0.75, 1.0)

var _basis: Basis = Basis.IDENTITY
var _time: float = 0.0


func _ready() -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2.ONE
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = BAR_SHADER
	material.render_priority = 9
	quad.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.use_custom_data = true
	multimesh.mesh = quad
	multimesh.instance_count = MAX_TOWERS
	multimesh.visible_instance_count = 0
	multimesh.custom_aabb = AABB(Vector3(-500, -10, -500), Vector3(1000, 40, 1000))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Hướng thanh theo camera (camera không xoay nên đặt một lần).
func face_camera(camera_basis: Basis) -> void:
	_basis = camera_basis


func update_bars(towers: Array[Tower], delta: float) -> void:
	_time += delta
	var used: int = 0
	for tower: Tower in towers:
		if used >= multimesh.instance_count:
			break
		var top: Vector3 = tower.global_position + Vector3(0.0, LIFT, 0.0)
		multimesh.set_instance_transform(used, Transform3D(_basis.scaled_local(Vector3(WIDTH, HEIGHT, 1.0)), top))
		multimesh.set_instance_color(used, color_for(tower.overload.state, _time))
		multimesh.set_instance_custom_data(used, Color(tower.overload.display_fill(), 0.0, 0.0, 0.0))
		used += 1
	multimesh.visible_instance_count = used


static func color_for(state: Overload.State, time: float) -> Color:
	match state:
		Overload.State.READY:
			return READY.lerp(Color.WHITE, 0.5 + 0.5 * sin(time * 8.0))
		Overload.State.MEGA:
			return MEGA
		Overload.State.COOLDOWN:
			return COOLDOWN
	return CHARGING
