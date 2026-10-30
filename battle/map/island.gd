class_name Island
extends Node3D
## Đảo khối thô dựng từ MapLayout: gộp mọi khối cùng màu vào một mesh để chỉ tốn một lệnh vẽ mỗi màu,
## rồi đặt các bệ lô cốt.

const GROUND_COLOR: Color = Color(0.93, 0.91, 0.84)
const STRUCTURE_COLOR: Color = Color(0.16, 0.42, 0.66)
const PAD_SCENE: PackedScene = preload("res://battle/map/tower_pad.tscn")

var pads: Array[TowerPad] = []

## Khối đảo nghiêng quanh tâm của nó khi mất Độ Nổi; bệ là phao riêng nên không nghiêng theo.
var _body: Node3D


func build(layout: MapLayout) -> void:
	for child: Node in get_children():
		child.queue_free()
	pads.clear()
	_body = Node3D.new()
	_body.name = "Body"
	_body.position = body_pivot(layout.island_blocks)
	add_child(_body)
	_add_blocks("Ground", layout.island_blocks, GROUND_COLOR)
	_add_blocks("Structures", layout.structure_blocks, STRUCTURE_COLOR)
	for i: int in layout.pad_positions.size():
		var pad: TowerPad = PAD_SCENE.instantiate()
		pad.name = "TowerPad%d" % i
		pad.pad_index = i
		pad.position = layout.pad_positions[i]
		add_child(pad)
		pads.append(pad)


## Nghiêng khối đảo: mép phía biển (−z) chìm xuống.
func set_tilt(degrees: float) -> void:
	if _body != null:
		_body.rotation_degrees.x = -degrees


func tilt_degrees() -> float:
	return -_body.rotation_degrees.x if _body != null else 0.0


## Tâm nghiêng: giữa các khối nền, ở mực nước.
static func body_pivot(blocks: Array[AABB]) -> Vector3:
	if blocks.is_empty():
		return Vector3.ZERO
	var bounds: AABB = blocks[0]
	for block: AABB in blocks:
		bounds = bounds.merge(block)
	var center: Vector3 = bounds.get_center()
	return Vector3(center.x, 0.0, center.z)


## Bệ gần điểm trên mặt nước nhất, trong bán kính max_distance; không có thì trả null.
func pad_near(point: Vector3, max_distance: float) -> TowerPad:
	var best: TowerPad = null
	var best_distance: float = max_distance
	for pad: TowerPad in pads:
		var d: float = Vector2(pad.position.x - point.x, pad.position.z - point.z).length()
		if d <= best_distance:
			best = pad
			best_distance = d
	return best


func _add_blocks(node_name: String, blocks: Array[AABB], color: Color) -> void:
	if blocks.is_empty():
		return
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = merge_boxes(blocks)
	instance.position = -_body.position
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(instance)


## Gộp các hộp thành một mesh duy nhất.
static func merge_boxes(blocks: Array[AABB]) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var box: BoxMesh = BoxMesh.new()
	for block: AABB in blocks:
		box.size = block.size
		var xform: Transform3D = Transform3D(Basis.IDENTITY, block.get_center())
		st.append_from(box, 0, xform)
	return st.commit()
