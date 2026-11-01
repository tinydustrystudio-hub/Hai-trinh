class_name AllianceFortress
extends RefCounted
## Dựng bằng code pháo đài nổi của Liên Minh Mũi Neo (GDD mục 8.6) cho tới khi có model thật:
## lục giác nhiều tầng; tháp chỉ huy kiêm hải đăng ở giữa; vành trong là xưởng, tua-bin dòng triều,
## chảo ra-đa; vành ngoài là đê chắn sóng có mỏm bến mang bệ, cần cẩu, cọc neo, phao cam.
## Kèm đảo vệ tinh (một bệ, một cột neo, một phao cam). Khối gộp thành ít mesh tô bằng màu đỉnh.
## Kích thước tính theo bán kính pháo đài để đổi cỡ vẫn cân đối.

const IVORY: Color = Color(0.88, 0.85, 0.77)
const SEA_BLUE: Color = Color(0.13, 0.36, 0.6)
const DEEP_BLUE: Color = Color(0.08, 0.2, 0.36)
const ORANGE: Color = Color(1.0, 0.45, 0.1)
const STEEL: Color = Color(0.32, 0.36, 0.4)
const DARK: Color = Color(0.12, 0.13, 0.15)
const GLASS: Color = Color(0.45, 0.7, 0.85)
const LAMP: Color = Color(1.0, 0.82, 0.45)

## Mặt sàn chính của pháo đài.
const DECK_Y: float = 0.8
## Sàn vành ngoài xám thép nhạt, để tách khỏi vành trong trắng ngà.
const DECK: Color = Color(0.55, 0.61, 0.66)
## Mặt mỏm bến và đảo vệ tinh (bệ đặt lên trên).
const PIER_Y: float = 0.55
const BASE_BOTTOM: float = -1.2
const PIER_WIDTH: float = 3.4
const PIER_END_RADIUS: float = 2.4


## Khối đặc của pháo đài và các mỏm bến (nghiêng theo Độ Nổi).
static func build_fortress(layout: MapLayout) -> ArrayMesh:
	var st: SurfaceTool = MeshKit.begin()
	var c: Vector3 = layout.fortress_center
	var r: float = layout.fortress_radius
	_base_and_wall(st, c, r, layout.building_level(&"wave_shield"))
	_tidal_lines(st, c, r, layout.building_level(&"tidal_power"))
	_inner_ring(st, c, r, layout.building_level(&"tidal_power"))
	_tower(st, c, r)
	for i: int in layout.pad_count():
		if not layout.is_satellite_pad(i):
			_pier(st, c, r, layout.pad_positions[i])
	_cranes(st, c, r)
	FortressBuildings.build(st, layout)
	return MeshKit.commit(st)


## Đảo vệ tinh và phao cam quanh pháo đài (nổi riêng, không nghiêng theo pháo đài).
static func build_satellites(layout: MapLayout) -> ArrayMesh:
	var st: SurfaceTool = MeshKit.begin()
	for buoy: Vector3 in buoy_positions(layout):
		_buoy(st, buoy)
	for center: Vector3 in layout.satellite_centers:
		_satellite(st, center, layout.satellite_radius, layout.fortress_center)
	return MeshKit.commit(st)


## Phao cam quanh pháo đài (đứng yên, không thuộc đảo vệ tinh nào).
static func build_buoys(layout: MapLayout) -> ArrayMesh:
	var st: SurfaceTool = MeshKit.begin()
	for buoy: Vector3 in buoy_positions(layout):
		_buoy(st, buoy)
	return MeshKit.commit(st)


## Một đảo vệ tinh, tọa độ tương đối với tâm đảo (để đảo dập dìu riêng theo sóng).
static func build_satellite(layout: MapLayout, index: int) -> ArrayMesh:
	var st: SurfaceTool = MeshKit.begin()
	var center: Vector3 = layout.satellite_centers[index]
	_satellite(st, Vector3.ZERO, layout.satellite_radius, layout.fortress_center - center)
	var away: Vector3 = Vector3(center.x - layout.fortress_center.x, 0.0, center.z - layout.fortress_center.z).normalized()
	var utility_dir: Vector3 = (away - Vector3(-away.z, 0.0, away.x)).normalized()
	SatelliteUtilities.build(st, layout.satellite_utility(index), Vector3.ZERO, utility_dir)
	SatelliteUtilities.build_props(st, Vector3.ZERO, utility_dir)
	return MeshKit.commit(st)


## Đèn hải đăng: mesh riêng để dùng vật liệu phát sáng.
static func build_lamp(layout: MapLayout) -> ArrayMesh:
	var st: SurfaceTool = MeshKit.begin()
	var r: float = layout.fortress_radius
	MeshKit.prism(st, layout.fortress_center, r * 0.1, tower_top(r) + 0.3, tower_top(r) + 1.7, 12, LAMP, LAMP)
	return MeshKit.commit(st)


## Đỉnh thân tháp (nơi đặt ban công đèn).
static func tower_top(r: float) -> float:
	return r * 0.82


## Phao cam quanh đê chắn sóng: giữa hai mỏm bến, lệch khỏi chỗ luồng cập đảo.
static func buoy_positions(layout: MapLayout) -> PackedVector3Array:
	var result: PackedVector3Array = PackedVector3Array()
	var r: float = layout.fortress_radius * 1.2
	for k: int in 6:
		var a: float = deg_to_rad(60.0 * float(k) + 18.0)
		result.append(layout.fortress_center + Vector3(cos(a), 0.0, sin(a)) * r)
	return result


## Hướng ra ngoài của mỏm bến thứ k (giữa cạnh lục giác).
static func edge_angle(k: int) -> float:
	return deg_to_rad(30.0 + 60.0 * float(k))


## Chiều cao tường chắn sóng theo cấp (cấp 1 giữ như cũ, mỗi cấp cao thêm).
static func wall_height(level: int) -> float:
	return 1.1 + 0.3 * float(clampi(level, 1, 5) - 1)


## Độ dày tường theo cấp, nhân với r * 0.07.
static func wall_thickness_scale(level: int) -> float:
	return 1.0 + 0.15 * float(clampi(level, 1, 5) - 1)


## Tường chắn sóng bao quanh cả đảo (cấp công trình Tường Chắn Sóng): cao và dày dần mỗi cấp; cấp 2 thêm sọc cam thứ hai,
## cấp 3 thêm chân tường chắn sóng, cấp 4 thêm đèn trên tường và tháp góc cao hơn, cấp 5 thêm hàng kính chắn gió trên đỉnh.
static func _base_and_wall(st: SurfaceTool, c: Vector3, r: float, wall_level: int = 1) -> void:
	# Phao nền lục giác (đỉnh ở 0°, 60°…), sàn trắng ngà.
	MeshKit.prism(st, c, r, BASE_BOTTOM, DECK_Y, 6, SEA_BLUE, DECK)
	# Gờ tối sát mặt nước cho rõ đường mớn.
	MeshKit.ring(st, c, r - 0.05, r + 0.15, -0.3, 0.25, 6, DEEP_BLUE, DEEP_BLUE)
	var inradius: float = r * cos(PI / 6.0)
	var gap: float = PIER_WIDTH + 0.6
	var thickness: float = r * 0.07 * wall_thickness_scale(wall_level)
	var height: float = wall_height(wall_level)
	for k: int in 6:
		var v0: Vector3 = c + Vector3(cos(deg_to_rad(60.0 * k)), 0.0, sin(deg_to_rad(60.0 * k))) * (r - thickness * 0.6)
		var v1: Vector3 = c + Vector3(cos(deg_to_rad(60.0 * (k + 1))), 0.0, sin(deg_to_rad(60.0 * (k + 1)))) * (r - thickness * 0.6)
		var along: Vector3 = (v1 - v0).normalized()
		var edge_len: float = v0.distance_to(v1)
		var seg_len: float = (edge_len - gap) * 0.5
		var yaw: float = atan2(-along.z, along.x)
		var outward: Vector3 = Vector3(cos(edge_angle(k)), 0.0, sin(edge_angle(k)))
		for side: int in 2:
			var start: Vector3 = v0 if side == 0 else v1 - along * seg_len
			var mid: Vector3 = start + along * seg_len * 0.5
			# Đê chắn sóng trắng ngà, sọc cam ở mặt ngoài.
			MeshKit.box(st, Vector3(mid.x, DECK_Y + height * 0.5, mid.z), Vector3(seg_len, height, thickness), IVORY, yaw)
			var stripe: Vector3 = mid + outward * (thickness * 0.5 + 0.03)
			MeshKit.box(st, Vector3(stripe.x, DECK_Y + 0.6, stripe.z), Vector3(seg_len * 0.98, 0.28, 0.06), ORANGE, yaw)
			if wall_level >= 2:
				MeshKit.box(st, Vector3(stripe.x, DECK_Y + height - 0.25, stripe.z), Vector3(seg_len * 0.98, 0.2, 0.06), ORANGE, yaw)
			if wall_level >= 3:
				var foot: Vector3 = mid + outward * (thickness * 0.5 + 0.35)
				MeshKit.box(st, Vector3(foot.x, DECK_Y + 0.2, foot.z), Vector3(seg_len, 0.45, 0.8), STEEL, yaw)
			if wall_level >= 4:
				MeshKit.box(st, Vector3(mid.x, DECK_Y + height + 0.35, mid.z), Vector3(0.3, 0.7, 0.3), DARK, yaw)
				MeshKit.box(st, Vector3(mid.x, DECK_Y + height + 0.85, mid.z), Vector3(0.45, 0.25, 0.45), LAMP, yaw)
			if wall_level >= 5:
				MeshKit.box(st, Vector3(mid.x, DECK_Y + height + 0.4, mid.z), Vector3(seg_len * 0.96, 0.8, 0.06), GLASS.lightened(0.2), yaw)
		# Pháo đài góc (bastion) ở mỗi đỉnh lục giác.
		var tower_top: float = DECK_Y + 1.6 + 0.35 * float(wall_level - 1)
		MeshKit.prism(st, v0, r * 0.1, DECK_Y - 0.4, tower_top, 6, IVORY, SEA_BLUE, deg_to_rad(60.0 * k))
		MeshKit.ring(st, v0, r * 0.1, r * 0.112, tower_top - 0.3, tower_top, 6, ORANGE, ORANGE, deg_to_rad(60.0 * k))
		if wall_level >= 4:
			MeshKit.cone(st, v0, r * 0.075, tower_top, 0.9, 6, SEA_BLUE)
	# Lối đi trên sàn từ mỗi khe đê vào vành trong.
	for k: int in 6:
		var dir: Vector3 = Vector3(cos(edge_angle(k)), 0.0, sin(edge_angle(k)))
		var p: Vector3 = c + dir * (inradius * 0.83)
		MeshKit.box(st, Vector3(p.x, DECK_Y + 0.02, p.z), Vector3(r * 0.24, 0.04, PIER_WIDTH * 0.7), STEEL.lightened(0.3), atan2(-dir.z, dir.x))


## Trạm Năng Lượng: từ cấp 2 có ống dẫn cáp cam chạy quanh mép sàn toàn đảo; cấp 4 thêm dải điện lam sáng bên cạnh.
static func _tidal_lines(st: SurfaceTool, c: Vector3, r: float, level: int) -> void:
	if level < 2:
		return
	var radius: float = r * 0.9
	for k: int in 6:
		var a0: float = deg_to_rad(60.0 * float(k) + 8.0)
		var a1: float = deg_to_rad(60.0 * float(k) + 22.0)
		var p0: Vector3 = c + Vector3(cos(a0), 0.0, sin(a0)) * radius
		var p1: Vector3 = c + Vector3(cos(a1), 0.0, sin(a1)) * radius
		var mid: Vector3 = (p0 + p1) * 0.5
		var along: Vector3 = p1 - p0
		var yaw: float = atan2(-along.z, along.x)
		MeshKit.box(st, Vector3(mid.x, DECK_Y + 0.12, mid.z), Vector3(along.length(), 0.24, 0.35), ORANGE, yaw)
		if level >= 4:
			MeshKit.box(st, Vector3(mid.x, DECK_Y + 0.27, mid.z), Vector3(along.length(), 0.06, 0.18), GLASS.lightened(0.5), yaw)


static func _inner_ring(st: SurfaceTool, c: Vector3, r: float, tidal_level: int = 1) -> void:
	var ring_r: float = r * 0.66
	var y_top: float = DECK_Y + 1.25
	# Tầng hai: lục giác xoay 30°, thân xanh biển, viền cam, mặt sáng.
	MeshKit.prism(st, c, ring_r, DECK_Y - 0.1, y_top, 6, SEA_BLUE, IVORY.darkened(0.06), deg_to_rad(30.0))
	MeshKit.ring(st, c, ring_r - 0.05, ring_r + 0.12, y_top - 0.25, y_top + 0.05, 6, ORANGE, ORANGE, deg_to_rad(30.0))
	# Sáu khối công trình quanh vành trong.
	var builders: Array[Callable] = [_workshop, _turbine, _radar, _containers, _turbine, _tanks]
	for k: int in 6:
		# Trạm Năng Lượng: cấp 1 một tua-bin; cấp 2 thêm khối pin; cấp 3 thêm tua-bin thứ hai; cấp 4 thêm pin cho nó;
		# cấp 5 thêm vòng tụ phát sáng ở cả hai.
		if k == 4 and tidal_level < 3:
			continue
		var a: float = deg_to_rad(60.0 * float(k))
		var dir: Vector3 = Vector3(cos(a), 0.0, sin(a))
		var at: Vector3 = c + dir * ring_r * 0.66 + Vector3(0, y_top, 0)
		builders[k].call(st, at, r, a)
		if k == 1 and tidal_level >= 2:
			_battery(st, at, r, a, tidal_level >= 5)
		elif k == 4 and tidal_level >= 4:
			_battery(st, at, r, a, tidal_level >= 5)


static func _workshop(st: SurfaceTool, at: Vector3, r: float, a: float) -> void:
	var s: float = r * 0.075
	MeshKit.box(st, at + Vector3(0, s * 1.0, 0), Vector3(s * 4.2, s * 2.0, s * 3.0), SEA_BLUE.lightened(0.15), -a, IVORY)
	# Mái răng cưa hai bậc, cửa cam.
	MeshKit.box(st, at + Vector3(0, s * 2.3, 0), Vector3(s * 3.6, s * 0.6, s * 1.4), IVORY, -a)
	var front: Vector3 = Vector3(cos(a), 0, sin(a)) * s * 1.52
	MeshKit.box(st, at + front + Vector3(0, s * 0.7, 0), Vector3(s * 1.6, s * 1.4, 0.06), ORANGE, -a)


static func _turbine(st: SurfaceTool, at: Vector3, r: float, a: float) -> void:
	var s: float = r * 0.075
	MeshKit.prism(st, at, s * 1.1, at.y, at.y + s * 0.6, 10, STEEL, IVORY)
	MeshKit.prism(st, at, s * 0.28, at.y + s * 0.6, at.y + s * 5.0, 8, IVORY, IVORY, 0.0, s * 0.2)
	var hub: Vector3 = at + Vector3(0, s * 5.0, 0)
	MeshKit.box(st, hub, Vector3(s * 0.8, s * 0.6, s * 1.4), IVORY, -a)
	# Ba cánh tua-bin, đầu cánh sơn cam.
	var face: Vector3 = Vector3(cos(a), 0, sin(a))
	var side: Vector3 = Vector3(-sin(a), 0, cos(a))
	for i: int in 3:
		var t: float = TAU * float(i) / 3.0 + 0.4
		var blade_dir: Vector3 = side * cos(t) + Vector3.UP * sin(t)
		var center: Vector3 = hub + face * s * 0.8 + blade_dir * s * 1.6
		var blade_basis: Basis = Basis(blade_dir.cross(face).normalized(), blade_dir, face)
		_oriented_box(st, center, blade_basis, Vector3(s * 0.35, s * 3.0, s * 0.1), IVORY)
		_oriented_box(st, hub + face * s * 0.8 + blade_dir * s * 2.9, blade_basis, Vector3(s * 0.36, s * 0.4, s * 0.11), ORANGE)


static func _battery(st: SurfaceTool, at: Vector3, r: float, a: float, glowing: bool) -> void:
	var s: float = r * 0.075
	var side: Vector3 = Vector3(-sin(a), 0, cos(a))
	MeshKit.box(st, at + side * s * 1.9 + Vector3(0, s * 0.55, 0), Vector3(s * 1.2, s * 1.1, s * 1.2), STEEL, -a, IVORY)
	if glowing:
		MeshKit.ring(st, at, s * 1.15, s * 1.3, at.y + s * 0.6, at.y + s * 0.8, 10, GLASS.lightened(0.3), GLASS.lightened(0.5))
		MeshKit.box(st, at + side * s * 1.9 + Vector3(0, s * 1.3, 0), Vector3(s * 0.5, s * 0.3, s * 0.5), GLASS.lightened(0.5), -a)


static func _radar(st: SurfaceTool, at: Vector3, r: float, a: float) -> void:
	var s: float = r * 0.075
	MeshKit.prism(st, at, s * 1.0, at.y, at.y + s * 1.4, 8, SEA_BLUE.lightened(0.1), IVORY)
	MeshKit.prism(st, at, s * 0.2, at.y + s * 1.4, at.y + s * 2.6, 6, STEEL, STEEL)
	# Chảo: nón dẹt ngửa, nghiêng ra ngoài.
	var tilt: Basis = Basis(Vector3(-sin(a), 0, cos(a)), deg_to_rad(35.0))
	var dish_center: Vector3 = at + Vector3(0, s * 2.9, 0)
	var sides: int = 14
	var rim: float = s * 1.6
	for i: int in sides:
		var a0: float = TAU * float(i) / float(sides)
		var a1: float = TAU * float(i + 1) / float(sides)
		var p0: Vector3 = dish_center + tilt * Vector3(cos(a0) * rim, s * 0.5, sin(a0) * rim)
		var p1: Vector3 = dish_center + tilt * Vector3(cos(a1) * rim, s * 0.5, sin(a1) * rim)
		var n: Vector3 = tilt * Vector3.UP
		MeshKit.tri(st, dish_center, p0, p1, n, IVORY.darkened(0.15), IVORY, IVORY)
		MeshKit.tri(st, dish_center, p1, p0, -n, STEEL, STEEL, STEEL)
	MeshKit.box(st, dish_center + tilt * Vector3(0, s * 1.2, 0), Vector3(s * 0.25, s * 0.25, s * 0.25), ORANGE)


static func _containers(st: SurfaceTool, at: Vector3, r: float, a: float) -> void:
	var s: float = r * 0.075
	var colors: Array[Color] = [ORANGE, SEA_BLUE.lightened(0.2), IVORY.darkened(0.1), ORANGE.darkened(0.15)]
	for i: int in 4:
		var row: float = float(i % 2) - 0.5
		var level: float = float(i / 2)
		var side: Vector3 = Vector3(-sin(a), 0, cos(a)) * row * s * 1.3
		MeshKit.box(st, at + side + Vector3(0, s * (0.6 + level * 1.2), 0), Vector3(s * 3.4, s * 1.15, s * 1.2), colors[i], -a)


static func _tanks(st: SurfaceTool, at: Vector3, r: float, a: float) -> void:
	var s: float = r * 0.075
	var side: Vector3 = Vector3(-sin(a), 0, cos(a))
	for i: int in 2:
		var p: Vector3 = at + side * s * (float(i) * 2.2 - 1.1)
		MeshKit.prism(st, p, s * 1.0, at.y, at.y + s * 2.6, 12, IVORY, IVORY.darkened(0.1))
		MeshKit.ring(st, p, s * 1.0, s * 1.04, at.y + s * 1.6, at.y + s * 2.0, 12, ORANGE, ORANGE)


static func _tower(st: SurfaceTool, c: Vector3, r: float) -> void:
	var plinth_r: float = r * 0.3
	var plinth_top: float = DECK_Y + 2.4
	# Bệ tháp: lục giác thứ ba, trắng ngà viền cam.
	MeshKit.prism(st, c, plinth_r, DECK_Y + 1.0, plinth_top, 6, IVORY, SEA_BLUE.lightened(0.25))
	MeshKit.ring(st, c, plinth_r - 0.02, plinth_r + 0.1, plinth_top - 0.2, plinth_top + 0.05, 6, ORANGE, ORANGE)
	# Thân tháp sọc trắng ngà và cam, thon dần.
	var top: float = tower_top(r)
	var base_r: float = r * 0.13
	var bands: int = 6
	for i: int in bands:
		var y0: float = lerpf(plinth_top, top, float(i) / float(bands))
		var y1: float = lerpf(plinth_top, top, float(i + 1) / float(bands))
		var r0: float = lerpf(base_r, base_r * 0.72, float(i) / float(bands))
		var r1: float = lerpf(base_r, base_r * 0.72, float(i + 1) / float(bands))
		MeshKit.prism(st, c, r0, y0, y1, 16, ORANGE if i % 2 == 1 else IVORY, IVORY, 0.0, r1)
	# Đài chỉ huy: vành kính xanh quanh lưng chừng tháp.
	var deck_y: float = lerpf(plinth_top, top, 0.42)
	MeshKit.prism(st, c, base_r * 1.45, deck_y, deck_y + 0.9, 16, SEA_BLUE, IVORY)
	MeshKit.ring(st, c, base_r * 1.46, base_r * 1.5, deck_y + 0.25, deck_y + 0.7, 16, GLASS, GLASS)
	# Ban công, phòng đèn (mesh riêng phát sáng), mũ nón xanh, chóp cam.
	MeshKit.prism(st, c, base_r * 1.1, top, top + 0.3, 16, DEEP_BLUE, DEEP_BLUE)
	MeshKit.ring(st, c, base_r * 1.05, base_r * 1.1, top + 0.3, top + 0.7, 16, DARK, DARK)
	MeshKit.cone(st, c, r * 0.1, top + 1.7, 1.0, 16, SEA_BLUE)
	MeshKit.prism(st, c, 0.12, top + 2.6, top + 3.4, 6, ORANGE, ORANGE)


static func _pier(st: SurfaceTool, c: Vector3, r: float, pad: Vector3) -> void:
	var dir: Vector3 = Vector3(pad.x - c.x, 0.0, pad.z - c.z).normalized()
	var start: float = r * cos(PI / 6.0) - 0.4
	var finish: float = Vector2(pad.x - c.x, pad.z - c.z).length()
	var length: float = finish - start
	var mid: Vector3 = c + dir * (start + length * 0.5)
	var yaw: float = atan2(-dir.z, dir.x)
	var depth: float = PIER_Y - BASE_BOTTOM * 0.6
	MeshKit.box(st, Vector3(mid.x, PIER_Y - depth * 0.5, mid.z), Vector3(length, depth, PIER_WIDTH), SEA_BLUE, yaw, IVORY)
	var side: Vector3 = Vector3(-dir.z, 0.0, dir.x)
	for s: float in [-1.0, 1.0]:
		# Sọc cam hai mép mỏm bến, cọc neo đen.
		var edge: Vector3 = mid + side * s * (PIER_WIDTH * 0.5 - 0.12)
		MeshKit.box(st, Vector3(edge.x, PIER_Y + 0.04, edge.z), Vector3(length * 0.92, 0.08, 0.24), ORANGE, yaw)
		for t: float in [0.3, 0.62]:
			var bollard: Vector3 = c + dir * (start + length * t) + side * s * (PIER_WIDTH * 0.5 - 0.45)
			MeshKit.prism(st, Vector3(bollard.x, 0, bollard.z), 0.22, PIER_Y, PIER_Y + 0.5, 8, DARK, STEEL)
	# Đầu mỏm tròn mang bệ.
	var end: Vector3 = Vector3(pad.x, 0.0, pad.z)
	MeshKit.prism(st, end, PIER_END_RADIUS, BASE_BOTTOM * 0.6, PIER_Y, 20, SEA_BLUE, IVORY)
	MeshKit.ring(st, end, PIER_END_RADIUS - 0.02, PIER_END_RADIUS + 0.12, PIER_Y - 0.35, PIER_Y + 0.02, 20, ORANGE, ORANGE)


static func _cranes(st: SurfaceTool, c: Vector3, r: float) -> void:
	# Hai cần cẩu ở góc đê không có luồng cập vào (60° và 240°).
	for deg: float in [60.0, 240.0]:
		var a: float = deg_to_rad(deg)
		var dir: Vector3 = Vector3(cos(a), 0, sin(a))
		var base: Vector3 = c + dir * (r - r * 0.07)
		var height: float = r * 0.62
		var mast_y: float = DECK_Y + 1.6
		MeshKit.box(st, base + Vector3(0, mast_y + height * 0.5, 0), Vector3(0.55, height, 0.55), ORANGE)
		var yaw: float = atan2(-dir.z, dir.x) + deg_to_rad(20.0)
		var jib_dir: Vector3 = Vector3(cos(-yaw), 0, sin(-yaw))
		var top: Vector3 = base + Vector3(0, mast_y + height, 0)
		MeshKit.box(st, top + jib_dir * r * 0.2, Vector3(r * 0.55, 0.4, 0.4), ORANGE, yaw)
		MeshKit.box(st, top - jib_dir * r * 0.08, Vector3(r * 0.14, 0.8, 0.8), DARK, yaw)
		MeshKit.box(st, top + Vector3(0, 0.6, 0), Vector3(0.9, 0.9, 0.9), IVORY, yaw)
		var hook: Vector3 = top + jib_dir * r * 0.42
		MeshKit.box(st, hook - Vector3(0, height * 0.3, 0), Vector3(0.06, height * 0.6, 0.06), DARK)
		MeshKit.box(st, hook - Vector3(0, height * 0.62, 0), Vector3(0.5, 0.4, 0.5), DARK)


static func _buoy(st: SurfaceTool, at: Vector3) -> void:
	MeshKit.prism(st, at, 0.5, -0.3, 0.45, 10, ORANGE, ORANGE, 0.0, 0.42)
	MeshKit.cone(st, at, 0.42, 0.45, 0.55, 10, ORANGE.lightened(0.1))
	MeshKit.ring(st, at, 0.49, 0.52, 0.05, 0.22, 10, IVORY, IVORY)
	MeshKit.prism(st, at, 0.06, 1.0, 1.4, 6, DARK, DARK)


static func _satellite(st: SurfaceTool, center: Vector3, radius: float, fortress: Vector3) -> void:
	# Phao tròn gỗ ghép, mặt trắng ngà, viền cam.
	MeshKit.prism(st, center, radius, -0.9, PIER_Y - 0.1, 24, Color(0.42, 0.33, 0.24), IVORY)
	MeshKit.ring(st, center, radius - 0.02, radius + 0.1, PIER_Y - 0.45, PIER_Y - 0.08, 24, ORANGE, ORANGE)
	MeshKit.ring(st, center, radius - 0.05, radius + 0.15, -0.3, 0.1, 24, DEEP_BLUE, DEEP_BLUE)
	# Cột neo ở phía xa pháo đài, phao cam buộc xích.
	var away: Vector3 = Vector3(center.x - fortress.x, 0.0, center.z - fortress.z).normalized()
	var side: Vector3 = Vector3(-away.z, 0.0, away.x)
	var post: Vector3 = center + (away * 0.7 + side * 0.7).normalized() * (radius - 0.45)
	MeshKit.prism(st, post, 0.26, PIER_Y - 0.1, PIER_Y + 1.6, 8, DARK, ORANGE)
	MeshKit.ring(st, post, 0.26, 0.3, PIER_Y + 1.2, PIER_Y + 1.6, 8, ORANGE, ORANGE)
	var buoy: Vector3 = center + (away * 0.7 + side * 0.7).normalized() * (radius + 1.6)
	_buoy(st, buoy)
	var chain_mid: Vector3 = (post + buoy) * 0.5
	var chain_dir: Vector3 = (buoy - post)
	MeshKit.box(st, Vector3(chain_mid.x, 0.35, chain_mid.z), Vector3(chain_dir.length(), 0.08, 0.08), DARK, atan2(-chain_dir.z, chain_dir.x))


static func _oriented_box(st: SurfaceTool, center: Vector3, basis: Basis, size: Vector3, color: Color) -> void:
	var h: Vector3 = size * 0.5
	var axes: Array[Vector3] = [basis.x.normalized(), basis.y.normalized(), basis.z.normalized()]
	for i: int in 3:
		for s: float in [-1.0, 1.0]:
			var n: Vector3 = axes[i] * s
			var u: Vector3 = axes[(i + 1) % 3] * h[(i + 1) % 3]
			var v: Vector3 = axes[(i + 2) % 3] * h[(i + 2) % 3]
			var face: Vector3 = center + n * h[i]
			MeshKit.quad(st, face - u - v, face + u - v, face + u + v, face - u + v, n, color, color)
