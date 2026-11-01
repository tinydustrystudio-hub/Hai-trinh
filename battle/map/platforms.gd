class_name Platforms
extends RefCounted
## Nhà giàn cố định trên biển của từng màn (MapLayout.platform_centers / platform_kinds): mỗi nhà giàn mang một bệ lô cốt đặt
## trên sàn. Hình dạng theo chủng loại, dựng bằng Blender (assets/models/plt_<loại>.glb): giàn khoan dầu khí cũ, nhà giàn
## quân sự, trạm nghiên cứu... Mô hình dùng toạ độ cục bộ: gốc ở mặt nước giữa giàn, +z là phía bãi đáp/mặt trước.

const OLD_OIL_RIG: StringName = &"old_oil_rig"
## Độ cao mặt sàn (đơn vị Godot) của từng loại.
const DECK_HEIGHT: Dictionary[StringName, float] = {
	&"old_oil_rig": 2.2,
}


static func model_name(kind: StringName) -> String:
	return "plt_%s" % String(kind)


static func has_model(kind: StringName) -> bool:
	return ModelMesh.exists(model_name(kind))


static func deck_height(kind: StringName) -> float:
	return DECK_HEIGHT.get(kind, 2.2)


## Góc quay quanh trục đứng để mặt trước (+z) của nhà giàn hướng ra xa tâm đảo chính.
static func yaw_for(center: Vector3, fortress_center: Vector3) -> float:
	var away: Vector3 = center - fortress_center
	return atan2(away.x, away.z)
