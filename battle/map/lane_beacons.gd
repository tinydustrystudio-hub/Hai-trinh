class_name LaneBeacons
extends Node3D
## Đèn báo hướng địch trên đảo chính (góp ý 3 của đạo diễn, thay cho chữ "từ luồng nào"): mỗi luồng một cột
## đèn trên pháo đài góc ở đỉnh lục giác nơi luồng cập đảo. Khi luồng sắp có địch, đèn nháy đỏ cam và
## chiếu một vệt sáng quét ra mặt nước về phía địch sẽ tới; địch đã ra thì tắt.
## Gắn vào thân pháo đài nên nghiêng theo Độ Nổi. Tất cả đầu đèn chung một lệnh vẽ, tất cả vệt sáng chung một lệnh vẽ.

const BEACON_SHADER: Shader = preload("res://battle/map/beacon.gdshader")
const BEAM_SHADER: Shader = preload("res://battle/map/beacon_beam.gdshader")
const MAX_BEACONS: int = 4
## Cột đèn đứng trên pháo đài góc (cao DECK_Y + 1.6).
const MAST_BOTTOM: float = AllianceFortress.DECK_Y + 1.6
const MAST_TOP: float = MAST_BOTTOM + 2.4
const HEAD_HEIGHT: float = 1.2
const HEAD_RADIUS: float = 0.75
## Vệt sáng trên mặt nước: bắt đầu từ chân pháo đài, dài BEAM_LENGTH, mở góc BEAM_HALF_ANGLE mỗi bên.
const BEAM_LENGTH: float = 34.0
const BEAM_HALF_ANGLE: float = deg_to_rad(15.0)
const BEAM_Y: float = 0.62
const BEAM_SEGMENTS: int = 10

## Vị trí cột đèn (trên mặt nước, theo tọa độ trận) và hướng địch tới của từng luồng.
var positions: PackedVector3Array = PackedVector3Array()
var directions: PackedVector3Array = PackedVector3Array()

var _active: PackedFloat32Array = PackedFloat32Array()
var _head_material: ShaderMaterial
var _beam_material: ShaderMaterial
var _beams: MeshInstance3D


## Dựng đèn từ bố cục; offset đổi tọa độ trận sang tọa độ của nút cha (thân pháo đài).
func build(layout: MapLayout, offset: Transform3D) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	positions.clear()
	directions.clear()
	var count: int = mini(layout.lane_count(), MAX_BEACONS)
	_active.resize(count)
	_active.fill(0.0)
	for i: int in count:
		positions.append(beacon_position(layout, i))
		directions.append(incoming_direction(layout, i))
	var solid: MeshInstance3D = _instance("Masts", _build_masts(), Island.solid_material(), offset)
	solid.name = "Masts"
	_head_material = ShaderMaterial.new()
	_head_material.shader = BEACON_SHADER
	_instance("Heads", _build_heads(), _head_material, offset)
	_beam_material = ShaderMaterial.new()
	_beam_material.shader = BEAM_SHADER
	_beam_material.set_shader_parameter(&"beam_length", BEAM_LENGTH)
	_beams = _instance("Beams", _build_beams(), _beam_material, offset)
	_apply()


## Bật hoặc tắt đèn báo của một luồng.
func set_active(lane_index: int, active: bool) -> void:
	if lane_index < 0 or lane_index >= _active.size():
		return
	var value: float = 1.0 if active else 0.0
	if _active[lane_index] == value:
		return
	_active[lane_index] = value
	_apply()


func is_active(lane_index: int) -> bool:
	return lane_index >= 0 and lane_index < _active.size() and _active[lane_index] > 0.0


func active_count() -> int:
	var total: int = 0
	for value: float in _active:
		if value > 0.0:
			total += 1
	return total


## Cột đèn đặt trên đỉnh lục giác gần chỗ luồng cập đảo nhất.
static func beacon_position(layout: MapLayout, lane_index: int) -> Vector3:
	var points: PackedVector3Array = layout.lane_points[lane_index]
	var end: Vector3 = points[points.size() - 1] - layout.fortress_center
	var angle: float = atan2(end.z, end.x)
	var vertex: float = deg_to_rad(60.0) * roundf(angle / deg_to_rad(60.0))
	var r: float = layout.fortress_radius - layout.fortress_radius * 0.07 * 0.6
	return layout.fortress_center + Vector3(cos(vertex), 0.0, sin(vertex)) * r


## Hướng (trên mặt nước) từ tâm đảo tới chỗ địch của luồng xuất phát: Bắc, Đông, Tây, Nam.
static func incoming_direction(layout: MapLayout, lane_index: int) -> Vector3:
	var start: Vector3 = layout.lane_points[lane_index][0] - layout.fortress_center
	start.y = 0.0
	return start.normalized() if start.length() > 0.001 else Vector3.FORWARD


func _apply() -> void:
	var flags: Vector4 = Vector4.ZERO
	for i: int in _active.size():
		flags[i] = _active[i]
	if _head_material != null:
		_head_material.set_shader_parameter(&"active_flags", flags)
	if _beam_material != null:
		_beam_material.set_shader_parameter(&"active_flags", flags)
	if _beams != null:
		_beams.visible = active_count() > 0


func _build_masts() -> ArrayMesh:
	var st: SurfaceTool = MeshKit.begin()
	for at: Vector3 in positions:
		MeshKit.prism(st, at, 0.14, MAST_BOTTOM - 0.1, MAST_TOP, 6, AllianceFortress.STEEL, AllianceFortress.STEEL)
		MeshKit.prism(st, at, HEAD_RADIUS * 1.15, MAST_TOP + HEAD_HEIGHT, MAST_TOP + HEAD_HEIGHT + 0.18, 8, AllianceFortress.DARK, AllianceFortress.DARK)
		MeshKit.prism(st, at, HEAD_RADIUS * 1.1, MAST_TOP - 0.15, MAST_TOP, 8, AllianceFortress.DARK, AllianceFortress.DARK)
	return MeshKit.commit(st)


## Đầu đèn: số thứ tự đèn nằm trong kênh đỏ của màu đỉnh, để một lệnh vẽ bật tắt từng đèn.
func _build_heads() -> ArrayMesh:
	var st: SurfaceTool = MeshKit.begin()
	for i: int in positions.size():
		var tag: Color = Color(index_tag(i), 0.0, 0.0)
		MeshKit.prism(st, positions[i], HEAD_RADIUS, MAST_TOP, MAST_TOP + HEAD_HEIGHT, 8, tag, tag)
	return MeshKit.commit(st)


func _build_beams() -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base: int = 0
	for i: int in positions.size():
		var tag: Color = Color(index_tag(i), 0.0, 0.0)
		var forward: Vector3 = directions[i]
		var origin: Vector3 = Vector3(positions[i].x, BEAM_Y, positions[i].z) + forward * 1.5
		var yaw: float = atan2(forward.z, forward.x)
		# Quạt: đỉnh ở cột đèn, vòm ngoài chia BEAM_SEGMENTS đoạn; UV.x ngang (0–1), UV.y dọc (0 ở gốc, 1 ở ngọn).
		st.set_color(tag)
		st.set_uv(Vector2(0.5, 0.0))
		st.add_vertex(origin)
		for k: int in BEAM_SEGMENTS + 1:
			var t: float = float(k) / float(BEAM_SEGMENTS)
			var a: float = yaw + lerpf(-BEAM_HALF_ANGLE, BEAM_HALF_ANGLE, t)
			st.set_color(tag)
			st.set_uv(Vector2(t, 1.0))
			st.add_vertex(origin + Vector3(cos(a), 0.0, sin(a)) * BEAM_LENGTH)
		for k: int in BEAM_SEGMENTS:
			st.add_index(base)
			st.add_index(base + k + 2)
			st.add_index(base + k + 1)
		base += BEAM_SEGMENTS + 2
	return st.commit()


## Số thứ tự đèn mã hóa thành một giá trị màu (0–1) để shader đọc lại.
static func index_tag(index: int) -> float:
	return (float(index) + 0.5) / float(MAX_BEACONS)


func _instance(node_name: String, mesh: Mesh, material: Material, offset: Transform3D) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.transform = offset
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance
