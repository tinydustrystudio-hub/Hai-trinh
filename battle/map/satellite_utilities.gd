class_name SatelliteUtilities
extends RefCounted
## Tiện ích đặt cạnh bệ trên đảo vệ tinh (concept pack mục D). Mỗi loại có hình bóng và màu nhấn riêng
## để phân biệt khi nhìn từ trên xuống: đĩa ra-đa, hai container, phao cứu hộ cam, tháp thon có chảo.
## Bến Thương Hội (trade_dock) chỉ dành cho đảo lãnh thổ, không có trong IDS.

const IDS: Array[StringName] = [&"radar_outpost", &"steel_depot", &"buoy_station", &"comms_tower"]
## Khoảng cách từ tâm đảo tới tiện ích (bệ lô cốt ở tâm).
const OFFSET: float = 2.5

const _SURFACE_Y: float = 0.45


## Tên mô hình Blender của tiện ích (assets/models/sat_<id>.glb); toạ độ cục bộ: gốc ở chỗ đặt trên mặt đảo, +x hướng ra ngoài.
static func model_name(id: StringName) -> String:
	return "sat_%s" % String(id)


static func has_model(id: StringName) -> bool:
	return ModelMesh.exists(model_name(id))


## Hướng đặt tiện ích trên đảo vệ tinh thứ index: lệch khỏi hướng nhìn ra xa đảo chính về một bên, để không đè lên cột neo.
static func direction_for(layout: MapLayout, index: int) -> Vector3:
	var center: Vector3 = layout.satellite_centers[index]
	var away: Vector3 = Vector3(center.x - layout.fortress_center.x, 0.0, center.z - layout.fortress_center.z).normalized()
	return (away - _side(away)).normalized()


## Vị trí cục bộ (trong đảo vệ tinh) và góc quay quanh trục đứng để đặt mô hình tiện ích.
static func model_transform(direction: Vector3) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, atan2(-direction.z, direction.x)), direction * OFFSET + Vector3(0.0, _SURFACE_Y, 0.0))


## Dựng tiện ích id, tâm tại center (tọa độ đảo), dịch về hướng direction (đơn vị, trên mặt nước).
static func build(st: SurfaceTool, id: StringName, center: Vector3, direction: Vector3) -> void:
	var at: Vector3 = center + direction * OFFSET
	at.y = _SURFACE_Y
	var yaw: float = atan2(-direction.z, direction.x)
	match id:
		&"radar_outpost":
			MeshKit.prism(st, at, 0.7, at.y, at.y + 0.5, 8, AllianceFortress.IVORY, AllianceFortress.STEEL)
			MeshKit.prism(st, at, 0.14, at.y + 0.5, at.y + 1.7, 6, AllianceFortress.STEEL, AllianceFortress.STEEL)
			_dish(st, at + Vector3(0, 2.0, 0), direction, 1.1)
		&"steel_depot":
			MeshKit.box(st, at + Vector3(0, 0.55, 0.0) + _side(direction) * 0.55, Vector3(1.9, 1.1, 0.9), AllianceFortress.SEA_BLUE, yaw, AllianceFortress.IVORY)
			MeshKit.box(st, at + Vector3(0, 0.55, 0.0) - _side(direction) * 0.55, Vector3(1.9, 1.1, 0.9), AllianceFortress.SEA_BLUE.lightened(0.15), yaw, AllianceFortress.IVORY)
			MeshKit.box(st, at + Vector3(0, 1.2, 0.0), Vector3(1.7, 0.12, 1.2), AllianceFortress.ORANGE, yaw)
		&"buoy_station":
			MeshKit.prism(st, at, 0.9, at.y, at.y + 0.5, 10, AllianceFortress.IVORY, AllianceFortress.IVORY)
			MeshKit.ring(st, at, 0.45, 0.95, at.y + 0.5, at.y + 1.1, 12, AllianceFortress.ORANGE, AllianceFortress.ORANGE)
			MeshKit.ring(st, at, 0.45, 0.95, at.y + 0.75, at.y + 0.85, 12, AllianceFortress.IVORY, AllianceFortress.IVORY, deg_to_rad(15.0))
		&"comms_tower":
			MeshKit.prism(st, at, 0.5, at.y, at.y + 0.4, 8, AllianceFortress.STEEL, AllianceFortress.IVORY)
			MeshKit.prism(st, at, 0.3, at.y + 0.4, at.y + 4.2, 8, AllianceFortress.IVORY, AllianceFortress.IVORY, 0.0, 0.12)
			MeshKit.box(st, at + Vector3(0, 3.0, 0) + direction * 0.4, Vector3(0.8, 0.8, 0.12), AllianceFortress.IVORY.darkened(0.1), yaw)
			MeshKit.box(st, at + Vector3(0, 4.4, 0), Vector3(0.3, 0.3, 0.3), AllianceFortress.LAMP)
		&"trade_dock":
			MeshKit.box(st, at + Vector3(0, 0.3, 0), Vector3(3.0, 0.3, 0.7), Color(0.78, 0.6, 0.4), yaw, AllianceFortress.IVORY)
			MeshKit.box(st, at + Vector3(0, 0.3, 0) - direction * 0.6, Vector3(0.7, 0.3, 3.0), Color(0.78, 0.6, 0.4), yaw)
			MeshKit.box(st, at + Vector3(0, 1.0, 0) + _side(direction) * 0.7, Vector3(0.9, 0.9, 0.9), AllianceFortress.IVORY, yaw)


## Đèn đường và cuộn dây neo nhỏ, đặt xa bệ và xa tiện ích.
static func build_props(st: SurfaceTool, center: Vector3, direction: Vector3) -> void:
	var lamp: Vector3 = center + (-direction * 0.6 + _side(direction)).normalized() * 3.0
	MeshKit.prism(st, Vector3(lamp.x, 0.0, lamp.z), 0.1, _SURFACE_Y, _SURFACE_Y + 1.2, 6, AllianceFortress.DARK, AllianceFortress.DARK)
	MeshKit.box(st, Vector3(lamp.x, _SURFACE_Y + 1.3, lamp.z), Vector3(0.26, 0.18, 0.26), AllianceFortress.LAMP)
	var coil: Vector3 = center + (-direction * 0.9 - _side(direction) * 0.6).normalized() * 2.8
	MeshKit.ring(st, Vector3(coil.x, 0.0, coil.z), 0.12, 0.34, _SURFACE_Y, _SURFACE_Y + 0.18, 8, AllianceFortress.IVORY, AllianceFortress.IVORY)


static func _side(direction: Vector3) -> Vector3:
	return Vector3(-direction.z, 0.0, direction.x)


static func _dish(st: SurfaceTool, at: Vector3, direction: Vector3, rim: float) -> void:
	var tilt: Basis = Basis(_side(direction), deg_to_rad(40.0))
	var n: Vector3 = tilt * Vector3.UP
	var sides: int = 12
	for i: int in sides:
		var a0: float = TAU * float(i) / float(sides)
		var a1: float = TAU * float(i + 1) / float(sides)
		var p0: Vector3 = at + tilt * Vector3(cos(a0) * rim, 0.3, sin(a0) * rim)
		var p1: Vector3 = at + tilt * Vector3(cos(a1) * rim, 0.3, sin(a1) * rim)
		MeshKit.tri(st, at, p0, p1, n, AllianceFortress.IVORY.darkened(0.15), AllianceFortress.IVORY, AllianceFortress.IVORY)
		MeshKit.tri(st, at, p1, p0, -n, AllianceFortress.STEEL, AllianceFortress.STEEL, AllianceFortress.STEEL)
	MeshKit.box(st, at + n * 0.9, Vector3(0.2, 0.2, 0.2), AllianceFortress.ORANGE)
