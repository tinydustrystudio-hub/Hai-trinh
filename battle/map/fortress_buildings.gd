class_name FortressBuildings
extends RefCounted
## Công trình hỗ trợ lên vành ngoài của pháo đài theo cấp 1 / 3 / 5 (concept pack mục C):
## Khiên Chắn Sóng (hàng trụ nghiêng), Xưởng Sửa Chữa (thêm băng chuyền, mái vòm), Xưởng Tàu (ụ nổi chữ U),
## cùng đèn đường dọc lối vào. Tất cả thấp hơn đê chắn sóng hoặc nằm trong vành đê, không che bệ hay luồng.

const SHIELD_ANGLE: float = 180.0
const SHIPYARD_ANGLES: Array[float] = [0.0, 120.0]
const REPAIR_ANGLE: float = 0.0
const DECK_RADIUS_FRACTION: float = 0.8


static func build(st: SurfaceTool, layout: MapLayout) -> void:
	var c: Vector3 = layout.fortress_center
	var r: float = layout.fortress_radius
	_wave_shield(st, c, r, layout.building_level(&"wave_shield"))
	_repair_extras(st, c, r, layout.building_level(&"repair_works"))
	_shipyard(st, c, r, layout.building_level(&"shipyard"))
	_lamp_posts(st, c, r)


## Số trụ của Khiên Chắn Sóng theo cấp.
static func shield_posts(level: int) -> int:
	return 1 if level < 3 else (3 if level < 5 else 5)


## Số ụ của Xưởng Tàu theo cấp (cấp 5 có hai ụ).
static func shipyard_docks(level: int) -> int:
	return 2 if level >= 5 else 1


static func _polar(c: Vector3, radius: float, degrees: float) -> Vector3:
	var a: float = deg_to_rad(degrees)
	return c + Vector3(cos(a), 0.0, sin(a)) * radius


static func _wave_shield(st: SurfaceTool, c: Vector3, r: float, level: int) -> void:
	var count: int = shield_posts(level)
	var y: float = AllianceFortress.DECK_Y
	var radius: float = r * 0.8
	var points: Array[Vector3] = []
	for i: int in count:
		var t: float = 0.0 if count == 1 else float(i) / float(count - 1) - 0.5
		var p: Vector3 = _polar(c, radius, SHIELD_ANGLE + t * 32.0)
		points.append(p)
		var outward: Vector3 = (p - c).normalized()
		var yaw: float = atan2(-outward.z, outward.x)
		# Trụ xám than có đầu cao su đen, sọc ngà, hơi nghiêng ra biển bằng một khối đế vát.
		MeshKit.box(st, Vector3(p.x, y + 0.9, p.z), Vector3(0.7, 1.8, 0.9), AllianceFortress.STEEL, yaw, AllianceFortress.DARK)
		MeshKit.box(st, Vector3(p.x, y + 1.55, p.z) + outward * 0.3, Vector3(0.5, 0.5, 0.7), AllianceFortress.IVORY, yaw)
	# Từ cấp 3 có dây chắn nối các trụ; cấp 5 thêm màng sóng lam nhạt.
	for i: int in range(1, points.size()):
		var a: Vector3 = points[i - 1]
		var b: Vector3 = points[i]
		var mid: Vector3 = (a + b) * 0.5
		var yaw: float = atan2(-(b - a).z, (b - a).x)
		MeshKit.box(st, Vector3(mid.x, y + 1.2, mid.z), Vector3(a.distance_to(b), 0.1, 0.1), AllianceFortress.DARK, yaw)
		if level >= 5:
			MeshKit.box(st, Vector3(mid.x, y + 0.75, mid.z), Vector3(a.distance_to(b), 0.9, 0.05), AllianceFortress.GLASS.lightened(0.2), yaw)


static func _repair_extras(st: SurfaceTool, c: Vector3, r: float, level: int) -> void:
	if level < 3:
		return
	var y: float = AllianceFortress.DECK_Y
	var base: Vector3 = _polar(c, r * 0.8, REPAIR_ANGLE)
	# Băng chuyền thấp dẫn ra phía xưởng, thùng vật liệu cam chạy trên đó.
	MeshKit.box(st, Vector3(base.x, y + 0.15, base.z), Vector3(3.6, 0.3, 1.0), AllianceFortress.DARK.lightened(0.15), 0.0)
	for i: int in 3:
		MeshKit.box(st, Vector3(base.x - 1.2 + float(i) * 1.2, y + 0.55, base.z), Vector3(0.6, 0.5, 0.6), AllianceFortress.ORANGE)
	if level >= 5:
		# Mái vòm và cánh tay máy.
		MeshKit.prism(st, Vector3(base.x, 0.0, base.z + 2.0), 1.3, y, y + 1.4, 12, AllianceFortress.IVORY, AllianceFortress.GLASS, 0.0, 0.7)
		MeshKit.box(st, Vector3(base.x + 1.6, y + 1.6, base.z + 2.0), Vector3(0.3, 2.2, 0.3), AllianceFortress.ORANGE)
		MeshKit.box(st, Vector3(base.x + 1.0, y + 2.6, base.z + 2.0), Vector3(1.6, 0.3, 0.3), AllianceFortress.ORANGE)


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
		# Cầu cẩu ngang qua ụ.
		MeshKit.box(st, Vector3(base.x, y + 1.5, base.z), Vector3(0.3, 0.3, 3.4), AllianceFortress.ORANGE, yaw)
		# Cấp 3: thân tàu đang đóng nằm trong ụ.
		if level >= 3:
			MeshKit.box(st, Vector3(base.x, y + 0.45, base.z), Vector3(2.0, 0.4, 1.0), AllianceFortress.IVORY.darkened(0.1), yaw)
			MeshKit.box(st, Vector3(base.x, y + 0.8, base.z) - out * 0.4, Vector3(0.7, 0.4, 0.7), AllianceFortress.GLASS, yaw)


static func _lamp_posts(st: SurfaceTool, c: Vector3, r: float) -> void:
	var y: float = AllianceFortress.DECK_Y
	for k: int in 6:
		for side: float in [-1.0, 1.0]:
			var p: Vector3 = _polar(c, r * 0.77, 30.0 + 60.0 * float(k) + side * 13.0)
			MeshKit.prism(st, Vector3(p.x, 0.0, p.z), 0.12, y, y + 1.3, 6, AllianceFortress.DARK, AllianceFortress.DARK)
			MeshKit.box(st, Vector3(p.x, y + 1.4, p.z), Vector3(0.3, 0.2, 0.3), AllianceFortress.LAMP)
