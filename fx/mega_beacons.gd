class_name MegaBeacons
extends MultiMeshInstance3D
## Đèn báo MEGA (góp ý 3 và 8 của người duyệt): lô cốt nào đang MEGA thì có một vòng LED quay quanh chân và một cột
## sáng dựng thẳng lên; cột thấp dần theo thời gian MEGA còn lại, hết MEGA thì tắt. Lô cốt vừa đầy thanh Quá tải và
## đang chờ kích (READY) thì nhấp nháy hào quang vàng như "siêu xay da": vòng chớp nhanh, ngọn lửa sáng bập bùng quanh
## thân; chạm vào chính lô cốt đó để kích MEGA, không còn khay nút ở góc màn hình. Mọi lô cốt chung một
## MultiMesh (một lệnh vẽ); chỉ là đèn báo, nhẹ hơn nhiều so với hiệu ứng MEGA đầy đủ nên không tính vào
## giới hạn 2 hiệu ứng MEGA đầy đủ.

const SHADER: Shader = preload("res://fx/mega_beacon.gdshader")
const MAX_TOWERS: int = 16
const RING_INNER: float = 2.05
const RING_OUTER: float = 2.75
const RING_Y: float = TowerPad.TOP_HEIGHT + 0.25
const BEAM_RADIUS: float = 0.5
const BEAM_HEIGHT: float = 9.0
## Chiều cao ngọn lửa hào quang của lô cốt sẵn sàng (tỉ lệ cột sáng).
const READY_FLAME: float = 0.6
const SEGMENTS: int = 32
## Kênh đỏ của màu đỉnh: 0 = vòng LED, 1 = cột sáng.
const RING_TAG: float = 0.0
const BEAM_TAG: float = 1.0


func _ready() -> void:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	var mesh: ArrayMesh = build_mesh()
	mesh.surface_set_material(0, material)
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = mesh
	multimesh.instance_count = MAX_TOWERS
	multimesh.visible_instance_count = 0
	multimesh.custom_aabb = AABB(Vector3(-500, -10, -500), Vector3(1000, 40, 1000))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Đặt đèn cho các lô cốt đang MEGA hoặc sẵn sàng kích; trả số đèn đang bật.
func update_beacons(towers: Array[Tower]) -> int:
	var used: int = 0
	for tower: Tower in towers:
		if used >= MAX_TOWERS:
			break
		var state: Overload.State = tower.overload.state
		if state != Overload.State.MEGA and state != Overload.State.READY:
			continue
		multimesh.set_instance_transform(used, Transform3D(Basis.IDENTITY, tower.global_position))
		# r = phần MEGA còn lại (cột sáng thấp dần; READY thì ngọn lửa cố định), g = pha riêng để các đèn không
		# nhịp cùng nhau, b = 1 khi đang chờ kích (hào quang nhấp nháy).
		var left: float = READY_FLAME if state == Overload.State.READY else tower.overload.display_fill()
		multimesh.set_instance_custom_data(used, Color(left, float(tower.get_instance_id() % 97) / 97.0, 1.0 if state == Overload.State.READY else 0.0, 0.0))
		used += 1
	multimesh.visible_instance_count = used
	return used


func active_count() -> int:
	return multimesh.visible_instance_count if multimesh != null else 0


## Vòng LED phẳng quanh chân bệ và ống sáng hở hai đầu. UV.x chạy quanh vòng (0–1); UV.y: bề ngang vòng,
## hoặc độ cao của cột (0 ở chân, 1 ở đỉnh).
static func build_mesh() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring_color: Color = Color(RING_TAG, 0.0, 0.0)
	var beam_color: Color = Color(BEAM_TAG, 0.0, 0.0)
	for i: int in SEGMENTS:
		var u0: float = float(i) / float(SEGMENTS)
		var u1: float = float(i + 1) / float(SEGMENTS)
		var d0: Vector3 = Vector3(cos(u0 * TAU), 0.0, sin(u0 * TAU))
		var d1: Vector3 = Vector3(cos(u1 * TAU), 0.0, sin(u1 * TAU))
		var y: Vector3 = Vector3(0.0, RING_Y, 0.0)
		_quad(st, ring_color,
			[y + d0 * RING_INNER, y + d1 * RING_INNER, y + d1 * RING_OUTER, y + d0 * RING_OUTER],
			[Vector2(u0, 0.0), Vector2(u1, 0.0), Vector2(u1, 1.0), Vector2(u0, 1.0)])
		var base: Vector3 = Vector3(0.0, TowerPad.TOP_HEIGHT, 0.0)
		var top: Vector3 = base + Vector3(0.0, BEAM_HEIGHT, 0.0)
		_quad(st, beam_color,
			[base + d0 * BEAM_RADIUS, base + d1 * BEAM_RADIUS, top + d1 * BEAM_RADIUS * 0.6, top + d0 * BEAM_RADIUS * 0.6],
			[Vector2(u0, 0.0), Vector2(u1, 0.0), Vector2(u1, 1.0), Vector2(u0, 1.0)])
	return st.commit()


static func _quad(st: SurfaceTool, color: Color, points: Array[Vector3], uvs: Array[Vector2]) -> void:
	for k: int in [0, 1, 2, 0, 2, 3]:
		st.set_color(color)
		st.set_uv(uvs[k])
		st.add_vertex(points[k])
