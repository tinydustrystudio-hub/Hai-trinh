class_name TowerMeshes
extends RefCounted
## Hình khối thô của lô cốt (phe Liên Minh: trắng ngà, xanh biển, sọc cam) cho tới khi có model thật.
## Thân đứng yên trên bệ; đầu nòng là mesh riêng để xoay. Mesh lưu theo loại lô cốt, dùng chung.

## Độ cao trục xoay của đầu nòng so với mặt bệ.
const TURRET_Y: float = 1.35
const BARREL_LENGTH: float = 1.6

static var _bases: Dictionary[StringName, ArrayMesh] = {}
static var _turrets: Dictionary[StringName, ArrayMesh] = {}
static var _material: StandardMaterial3D


static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.roughness = 0.6
	return _material


static func base_mesh(data: TowerData) -> ArrayMesh:
	if not _bases.has(data.id):
		var st: SurfaceTool = MeshKit.begin()
		var top: float = TowerPad.TOP_HEIGHT
		MeshKit.prism(st, Vector3.ZERO, 1.25, top, top + 0.55, 6, AllianceFortress.IVORY, AllianceFortress.IVORY.darkened(0.08), deg_to_rad(30.0))
		MeshKit.ring(st, Vector3.ZERO, 1.25, 1.3, top + 0.35, top + 0.55, 6, AllianceFortress.ORANGE, AllianceFortress.ORANGE, deg_to_rad(30.0))
		MeshKit.prism(st, Vector3.ZERO, 0.8, top + 0.55, TURRET_Y + top - 0.2, 12, data.color, data.color.lightened(0.2))
		_bases[data.id] = MeshKit.commit(st)
	return _bases[data.id]


## Đầu nòng, gốc ở trục xoay, nòng hướng về −z.
static func turret_mesh(data: TowerData) -> ArrayMesh:
	if not _turrets.has(data.id):
		var st: SurfaceTool = MeshKit.begin()
		var y: float = TowerPad.TOP_HEIGHT
		match data.id:
			&"machine_gun":
				# Ụ súng hộp, hai nòng đen, sọc cam trên nóc.
				MeshKit.box(st, Vector3(0, y, 0.1), Vector3(1.1, 0.6, 1.2), data.color.lightened(0.1), 0.0, AllianceFortress.IVORY)
				MeshKit.box(st, Vector3(0, y + 0.31, 0.1), Vector3(0.3, 0.04, 1.0), AllianceFortress.ORANGE)
				for x: float in [-0.22, 0.22]:
					MeshKit.box(st, Vector3(x, y + 0.05, -BARREL_LENGTH * 0.5), Vector3(0.14, 0.14, BARREL_LENGTH), AllianceFortress.DARK)
			&"glue_sprayer":
				# Bồn keo tròn màu rong biển, đai cam, vòi phun ngắn loe miệng.
				MeshKit.prism(st, Vector3(0, 0, 0.15), 0.62, y - 0.3, y + 0.45, 12, data.color, data.color.lightened(0.25))
				MeshKit.ring(st, Vector3(0, 0, 0.15), 0.62, 0.66, y - 0.05, y + 0.12, 12, AllianceFortress.ORANGE, AllianceFortress.ORANGE)
				MeshKit.box(st, Vector3(0, y + 0.1, -0.75), Vector3(0.22, 0.22, 1.0), AllianceFortress.STEEL)
				MeshKit.box(st, Vector3(0, y + 0.1, -1.3), Vector3(0.4, 0.4, 0.2), data.color.darkened(0.2))
			_:
				MeshKit.box(st, Vector3(0, y, 0), Vector3(1.0, 0.6, 1.0), data.color)
		_turrets[data.id] = MeshKit.commit(st)
	return _turrets[data.id]
