class_name BeamRenderer
extends MultiMeshInstance3D
## Vẽ mọi tia của Lô Cốt Tia Sáng bằng một MultiMesh (một lệnh vẽ). Mỗi nhịp: begin(), các lô cốt gọi draw(),
## rồi finish(). Mỗi tia gồm lõi trắng mảnh và quầng xanh lam rộng hơn (hai hộp lồng nhau); hội tụ càng lâu
## tia càng dày và sáng, MEGA thì sáng trắng nóng.

const MAX_BEAMS: int = 16
const CORE_WIDTH: float = 0.1
const HALO_WIDTH: float = 0.34
const HALO: Color = Color(0.3, 0.75, 1.0)
const CORE: Color = Color(0.9, 1.0, 1.0)
const MEGA: Color = Color(1.0, 0.95, 0.8)

var _used: int = 0


func _ready() -> void:
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3.ONE
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.vertex_color_use_as_albedo = true
	material.no_depth_test = true
	box.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = box
	multimesh.instance_count = MAX_BEAMS * 2
	multimesh.visible_instance_count = 0
	multimesh.custom_aabb = AABB(Vector3(-500, -10, -500), Vector3(1000, 40, 1000))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func begin() -> void:
	_used = 0


## Một tia từ from tới to; focus (0–1) là độ hội tụ; mega = tia MEGA.
func draw(from: Vector3, to: Vector3, focus: float, mega: bool) -> void:
	if _used + 2 > multimesh.instance_count:
		return
	var span: Vector3 = to - from
	var length: float = span.length()
	if length < 0.01:
		return
	var up: Vector3 = Vector3.UP if absf(span.normalized().y) < 0.99 else Vector3.RIGHT
	var look: Basis = Basis.looking_at(span / length, up)
	var middle: Vector3 = (from + to) * 0.5
	var grow: float = 1.0 + focus * 0.8 + (0.6 if mega else 0.0)
	var halo_color: Color = (MEGA if mega else HALO)
	halo_color.a = 0.28 + 0.25 * focus
	var core_color: Color = (MEGA if mega else CORE)
	core_color.a = 0.8
	multimesh.set_instance_transform(_used, Transform3D(look.scaled_local(Vector3(HALO_WIDTH * grow, HALO_WIDTH * grow, length)), middle))
	multimesh.set_instance_color(_used, halo_color)
	multimesh.set_instance_transform(_used + 1, Transform3D(look.scaled_local(Vector3(CORE_WIDTH * grow, CORE_WIDTH * grow, length)), middle))
	multimesh.set_instance_color(_used + 1, core_color)
	_used += 2


func finish() -> void:
	multimesh.visible_instance_count = _used


## Số tia đang vẽ.
func count() -> int:
	return _used / 2
