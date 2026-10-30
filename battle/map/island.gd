class_name Island
extends Node3D
## Đảo khối thô dựng từ MapLayout: gộp mọi khối cùng màu vào một mesh để chỉ tốn một lệnh vẽ mỗi màu,
## rồi đặt các bệ lô cốt.

const GROUND_COLOR: Color = Color(0.93, 0.91, 0.84)
const STRUCTURE_COLOR: Color = Color(0.16, 0.42, 0.66)
const PAD_SCENE: PackedScene = preload("res://battle/map/tower_pad.tscn")

var pads: Array[TowerPad] = []


func build(layout: MapLayout) -> void:
	for child: Node in get_children():
		child.queue_free()
	pads.clear()
	_add_blocks("Ground", layout.island_blocks, GROUND_COLOR)
	_add_blocks("Structures", layout.structure_blocks, STRUCTURE_COLOR)
	for i: int in layout.pad_positions.size():
		var pad: TowerPad = PAD_SCENE.instantiate()
		pad.name = "TowerPad%d" % i
		pad.pad_index = i
		pad.position = layout.pad_positions[i]
		add_child(pad)
		pads.append(pad)


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
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


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
