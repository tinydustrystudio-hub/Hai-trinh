class_name TowerMeshes
extends RefCounted
## Hình khối thô của lô cốt (phe Liên Minh: trắng ngà, xanh biển, sọc cam) cho tới khi có model thật.
## Thân đứng yên trên bệ; đầu nòng là mesh riêng để xoay. Mesh lưu theo loại lô cốt, dùng chung.
## Có assets/models/twr_<id>_base.glb và twr_<id>_turret.glb (dựng bằng Blender, tools/blender) thì dùng chúng, không thì dựng bằng code.

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
		var model: ArrayMesh = ModelMesh.load_mesh("twr_%s_base" % String(data.id))
		_bases[data.id] = model if model != null else code_base_mesh(data)
	return _bases[data.id]


## Đế dựng bằng code (dùng khi chưa có mô hình Blender, và để so sánh).
static func code_base_mesh(data: TowerData) -> ArrayMesh:
	var st: SurfaceTool = MeshKit.begin()
	var top: float = TowerPad.TOP_HEIGHT
	MeshKit.prism(st, Vector3.ZERO, 1.25, top, top + 0.55, 6, AllianceFortress.IVORY, AllianceFortress.IVORY.darkened(0.08), deg_to_rad(30.0))
	MeshKit.ring(st, Vector3.ZERO, 1.25, 1.3, top + 0.35, top + 0.55, 6, AllianceFortress.ORANGE, AllianceFortress.ORANGE, deg_to_rad(30.0))
	MeshKit.prism(st, Vector3.ZERO, 0.8, top + 0.55, TURRET_Y + top - 0.2, 12, data.color, data.color.lightened(0.2))
	return MeshKit.commit(st)


## Đầu nòng, gốc ở trục xoay, nòng hướng về −z.
static func turret_mesh(data: TowerData) -> ArrayMesh:
	if not _turrets.has(data.id):
		var model: ArrayMesh = ModelMesh.load_mesh("twr_%s_turret" % String(data.id))
		_turrets[data.id] = model if model != null else code_turret_mesh(data)
	return _turrets[data.id]


## Đầu nòng dựng bằng code (dùng khi chưa có mô hình Blender, và để so sánh).
static func code_turret_mesh(data: TowerData) -> ArrayMesh:
	var st: SurfaceTool = MeshKit.begin()
	var y: float = TowerPad.TOP_HEIGHT
	match data.id:
		&"machine_gun":
			# Súng quay bốn nòng: vỏ hộp trắng ngà có sọc cam, cụm nòng đen xếp ô vuông, hộp đạn bên hông, kính ngắm trên nóc.
			MeshKit.box(st, Vector3(0, y, 0.2), Vector3(1.2, 0.62, 1.0), data.color.lightened(0.1), 0.0, AllianceFortress.IVORY)
			MeshKit.box(st, Vector3(0, y + 0.33, 0.2), Vector3(0.28, 0.05, 0.9), AllianceFortress.ORANGE)
			MeshKit.box(st, Vector3(0.72, y - 0.05, 0.35), Vector3(0.3, 0.42, 0.55), AllianceFortress.STEEL)
			MeshKit.box(st, Vector3(-0.35, y + 0.45, 0.4), Vector3(0.22, 0.22, 0.4), AllianceFortress.DARK)
			MeshKit.box(st, Vector3(0, y + 0.02, -0.4), Vector3(0.62, 0.62, 0.3), AllianceFortress.DARK.lightened(0.1))
			for x: float in [-0.14, 0.14]:
				for dy: float in [-0.14, 0.14]:
					MeshKit.box(st, Vector3(x, y + 0.02 + dy, -BARREL_LENGTH * 0.5 - 0.1), Vector3(0.12, 0.12, BARREL_LENGTH - 0.2), AllianceFortress.DARK)
			MeshKit.box(st, Vector3(0, y + 0.02, -BARREL_LENGTH + 0.28), Vector3(0.5, 0.5, 0.1), AllianceFortress.ORANGE)
		&"glue_sprayer":
			# Bồn keo lớn màu rong biển có đai cam, ống áp lực đưa tới vòi phun hình loa to, đồng hồ áp suất trên nắp.
			MeshKit.prism(st, Vector3(0, 0, 0.35), 0.72, y - 0.3, y + 0.62, 12, data.color, data.color.lightened(0.25), 0.0, 0.6)
			MeshKit.ring(st, Vector3(0, 0, 0.35), 0.72, 0.76, y + 0.0, y + 0.16, 12, AllianceFortress.ORANGE, AllianceFortress.ORANGE)
			MeshKit.prism(st, Vector3(0, 0, 0.35), 0.18, y + 0.62, y + 0.82, 8, AllianceFortress.STEEL, AllianceFortress.IVORY)
			MeshKit.box(st, Vector3(0, y + 0.12, -0.55), Vector3(0.24, 0.24, 0.9), AllianceFortress.STEEL)
			MeshKit.prism(st, Vector3(0, 0, -1.35), 0.42, y - 0.12, y + 0.36, 10, data.color.darkened(0.25), AllianceFortress.DARK, 0.0, 0.2)
			MeshKit.box(st, Vector3(0, y + 0.12, -1.0), Vector3(0.5, 0.5, 0.12), AllianceFortress.ORANGE)
		&"light_beam":
			# Pháo tia: đế than chì, ống hội tụ dài, ba vòng hội tụ cam, thấu kính lam sáng ở đầu, hai cánh tản nhiệt dựng đứng.
			MeshKit.prism(st, Vector3(0, 0, 0.2), 0.62, y - 0.3, y + 0.35, 10, AllianceFortress.DARK.lightened(0.15), data.color.lightened(0.15))
			MeshKit.box(st, Vector3(0, y + 0.25, -0.5), Vector3(0.42, 0.42, 1.5), data.color)
			for z: float in [-0.2, -0.65, -1.1]:
				MeshKit.box(st, Vector3(0, y + 0.25, z), Vector3(0.62, 0.62, 0.1), AllianceFortress.ORANGE)
			MeshKit.box(st, Vector3(0, y + 0.25, -1.38), Vector3(0.74, 0.74, 0.16), AllianceFortress.DARK)
			MeshKit.box(st, Vector3(0, y + 0.25, -1.48), Vector3(0.5, 0.5, 0.08), AllianceFortress.GLASS.lightened(0.45))
			for x: float in [-0.5, 0.5]:
				MeshKit.box(st, Vector3(x, y + 0.7, 0.2), Vector3(0.08, 0.8, 0.9), AllianceFortress.ORANGE)
		_:
			MeshKit.box(st, Vector3(0, y, 0), Vector3(1.0, 0.6, 1.0), data.color)
	return MeshKit.commit(st)
