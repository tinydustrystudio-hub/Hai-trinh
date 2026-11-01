class_name FortressBuildings
extends RefCounted
## Công trình hỗ trợ lên vành ngoài của pháo đài theo cấp 1 / 3 / 5 (concept pack mục C):
## Xưởng Sửa Chữa (thêm băng chuyền, mái vòm), Xưởng Tàu (ụ nổi chữ U),
## cùng đèn đường dọc lối vào. Tất cả thấp hơn đê chắn sóng hoặc nằm trong vành đê, không che bệ hay luồng.

const SHIPYARD_ANGLES: Array[float] = [0.0, 120.0]
const REPAIR_ANGLE: float = 0.0
const DECK_RADIUS_FRACTION: float = 0.8


static func build(st: SurfaceTool, layout: MapLayout) -> void:
	var c: Vector3 = layout.fortress_center
	var r: float = layout.fortress_radius
	_repair_extras(st, c, r, layout.building_level(&"repair_works"))
	_shipyard(st, c, r, layout.building_level(&"shipyard"))
	_lamp_posts(st, c, r)


## Số ụ của Xưởng Tàu theo cấp (cấp 5 có hai ụ).
static func shipyard_docks(level: int) -> int:
	return 2 if level >= 5 else 1


## Cấp tối thiểu của từng phần Xưởng Tàu: cầu cẩu, thân tàu, buồng lái và cột.
const SHIPYARD_CRANE_LEVEL: int = 2
const SHIPYARD_HULL_LEVEL: int = 3
const SHIPYARD_CABIN_LEVEL: int = 4


static func _polar(c: Vector3, radius: float, degrees: float) -> Vector3:
	var a: float = deg_to_rad(degrees)
	return c + Vector3(cos(a), 0.0, sin(a)) * radius


static func _repair_extras(st: SurfaceTool, c: Vector3, r: float, level: int) -> void:
	if level < 2:
		return
	var y: float = AllianceFortress.DECK_Y
	var base: Vector3 = _polar(c, r * 0.8, REPAIR_ANGLE)
	# Cấp 2: băng chuyền thấp; mỗi cấp thêm một thùng vật liệu cam chạy trên đó.
	MeshKit.box(st, Vector3(base.x, y + 0.15, base.z), Vector3(4.4, 0.3, 1.1), AllianceFortress.DARK.lightened(0.15), 0.0)
	for i: int in mini(level - 1, 4):
		MeshKit.box(st, Vector3(base.x - 1.5 + float(i) * 1.0, y + 0.65, base.z), Vector3(0.7, 0.7, 0.7), AllianceFortress.ORANGE)
	if level >= 4:
		# Mái vòm kính; cấp 5 thêm tay máy.
		MeshKit.prism(st, Vector3(base.x, 0.0, base.z + 2.4), 1.5, y, y + 1.7, 12, AllianceFortress.IVORY, AllianceFortress.GLASS, 0.0, 0.8)
	if level >= 5:
		MeshKit.box(st, Vector3(base.x + 1.9, y + 2.0, base.z + 2.4), Vector3(0.35, 2.8, 0.35), AllianceFortress.ORANGE)
		MeshKit.box(st, Vector3(base.x + 1.1, y + 3.3, base.z + 2.4), Vector3(1.8, 0.35, 0.35), AllianceFortress.ORANGE)


static func _shipyard(st: SurfaceTool, c: Vector3, r: float, level: int) -> void:
	var y: float = AllianceFortress.DECK_Y
	for d: int in shipyard_docks(level):
		var base: Vector3 = _polar(c, r * 0.8, SHIPYARD_ANGLES[d] + (0.0 if d == 0 else 0.0))
		if d == 0:
			base.z += 0.0
		# Ụ nổi chữ U: đáy và hai mạn, mở ra phía biển.
		var out: Vector3 = (base - c).normalized()
		var yaw: float = atan2(-out.z, out.x)
		var side: Vector3 = Vector3(-out.z, 0.0, out.x)
		MeshKit.box(st, Vector3(base.x, y + 0.12, base.z), Vector3(2.8, 0.24, 3.0), AllianceFortress.SEA_BLUE, yaw, AllianceFortress.IVORY)
		for s: float in [-1.0, 1.0]:
			var wall: Vector3 = base + side * s * 1.5
			MeshKit.box(st, Vector3(wall.x, y + 0.6, wall.z), Vector3(2.8, 1.0, 0.3), AllianceFortress.SEA_BLUE, yaw, AllianceFortress.ORANGE)
		var back: Vector3 = base - out * 1.5
		MeshKit.box(st, Vector3(back.x, y + 0.6, back.z), Vector3(0.3, 1.0, 3.0), AllianceFortress.SEA_BLUE, yaw)
		# Cấp 2: cầu cẩu ngang qua ụ.
		if level >= SHIPYARD_CRANE_LEVEL:
			MeshKit.box(st, Vector3(base.x, y + 1.7, base.z), Vector3(0.4, 0.4, 3.6), AllianceFortress.ORANGE, yaw)
			for s: float in [-1.0, 1.0]:
				var leg: Vector3 = base + side * s * 1.7
				MeshKit.box(st, Vector3(leg.x, y + 0.9, leg.z), Vector3(0.4, 1.8, 0.4), AllianceFortress.ORANGE, yaw)
		# Cấp 3: thân tàu đang đóng nằm trong ụ.
		if level >= SHIPYARD_HULL_LEVEL:
			MeshKit.box(st, Vector3(base.x, y + 0.45, base.z), Vector3(2.0, 0.4, 1.0), AllianceFortress.IVORY.darkened(0.1), yaw)
		# Cấp 4: buồng lái kính và cột ăng-ten trên thân tàu.
		if level >= SHIPYARD_CABIN_LEVEL:
			MeshKit.box(st, Vector3(base.x, y + 0.95, base.z) - out * 0.4, Vector3(0.9, 0.6, 0.9), AllianceFortress.GLASS, yaw)
			MeshKit.box(st, Vector3(base.x, y + 1.6, base.z) - out * 0.4, Vector3(0.08, 0.9, 0.08), AllianceFortress.DARK)


static func _lamp_posts(st: SurfaceTool, c: Vector3, r: float) -> void:
	var y: float = AllianceFortress.DECK_Y
	for k: int in 6:
		for side: float in [-1.0, 1.0]:
			var p: Vector3 = _polar(c, r * 0.77, 30.0 + 60.0 * float(k) + side * 13.0)
			MeshKit.prism(st, Vector3(p.x, 0.0, p.z), 0.12, y, y + 1.3, 6, AllianceFortress.DARK, AllianceFortress.DARK)
			MeshKit.box(st, Vector3(p.x, y + 1.4, p.z), Vector3(0.3, 0.2, 0.3), AllianceFortress.LAMP)
