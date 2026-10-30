class_name MeshKit
extends RefCounted
## Hàm dựng hình khối thô vào một SurfaceTool: hộp, lăng trụ đa giác (lục giác, trụ tròn), vành, nón.
## Tô bằng màu đỉnh; mặt bên tối dần xuống chân (thay cho bóng nướng sẵn) để khối có chiều sâu.
## Thứ tự đỉnh của tam giác được tự đảo cho mặt trước luôn hướng ra ngoài.

## Mặt bên: chân khối tối hơn đỉnh khối theo tỉ lệ này.
const BOTTOM_SHADE: float = 0.62


static func begin() -> SurfaceTool:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


## Một tam giác; normal là hướng mặt trước mong muốn.
static func tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	# Godot coi mặt trước là mặt có (c − a) × (b − a) cùng hướng pháp tuyến.
	if (c - a).cross(b - a).dot(normal) < 0.0:
		var t: Vector3 = b
		b = c
		c = t
		var tc: Color = cb
		cb = cc
		cc = tc
	for pair: Array in [[a, ca], [b, cb], [c, cc]]:
		st.set_color(pair[1])
		st.set_normal(normal)
		st.add_vertex(pair[0])


## Tứ giác a-b-c-d (theo vòng), màu ca cho a, b và cd cho c, d.
static func quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3, ab_color: Color, cd_color: Color) -> void:
	tri(st, a, b, c, normal, ab_color, ab_color, cd_color)
	tri(st, a, c, d, normal, ab_color, cd_color, cd_color)


## Hộp có tâm center, kích thước size, xoay quanh trục đứng một góc yaw (radian).
static func box(st: SurfaceTool, center: Vector3, size: Vector3, color: Color, yaw: float = 0.0, top_color: Color = Color(0, 0, 0, 0)) -> void:
	var basis: Basis = Basis(Vector3.UP, yaw)
	var h: Vector3 = size * 0.5
	var top: Color = color if top_color.a == 0.0 else top_color
	var bottom: Color = color.darkened(1.0 - BOTTOM_SHADE)
	var corners: Array[Vector3] = []
	for sy: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			for sx: float in [-1.0, 1.0]:
				corners.append(center + basis * Vector3(sx * h.x, sy * h.y, sz * h.z))
	# Chỉ số: x nhanh nhất, rồi z, rồi y. Đáy 0..3, nắp 4..7.
	quad(st, corners[4], corners[5], corners[7], corners[6], Vector3.UP, top, top)
	quad(st, corners[0], corners[1], corners[3], corners[2], Vector3.DOWN, bottom, bottom)
	var sides: Array[Array] = [[4, 5, 1, 0, -basis.z], [7, 6, 2, 3, basis.z], [6, 4, 0, 2, -basis.x], [5, 7, 3, 1, basis.x]]
	for side: Array in sides:
		quad(st, corners[side[0]], corners[side[1]], corners[side[2]], corners[side[3]], side[4], color, bottom)


## Lăng trụ đa giác đều đứng: tâm đáy (center.x, y0, center.z), bán kính tới đỉnh, sides cạnh.
## yaw là góc của đỉnh đầu tiên (radian, quanh trục đứng, x = cos, z = sin).
static func prism(st: SurfaceTool, center: Vector3, radius: float, y0: float, y1: float, sides: int, side_color: Color, top_color: Color, yaw: float = 0.0, top_radius: float = -1.0) -> void:
	var r_top: float = radius if top_radius < 0.0 else top_radius
	var bottom: Color = side_color.darkened(1.0 - BOTTOM_SHADE)
	var top_center: Vector3 = Vector3(center.x, y1, center.z)
	for i: int in sides:
		var a0: float = yaw + TAU * float(i) / float(sides)
		var a1: float = yaw + TAU * float(i + 1) / float(sides)
		var d0: Vector3 = Vector3(cos(a0), 0.0, sin(a0))
		var d1: Vector3 = Vector3(cos(a1), 0.0, sin(a1))
		var b0: Vector3 = Vector3(center.x, y0, center.z) + d0 * radius
		var b1: Vector3 = Vector3(center.x, y0, center.z) + d1 * radius
		var t0: Vector3 = top_center + d0 * r_top
		var t1: Vector3 = top_center + d1 * r_top
		var outward: Vector3 = (d0 + d1).normalized()
		if r_top != radius:
			outward = (outward * (y1 - y0) + Vector3.UP * (radius - r_top)).normalized()
		quad(st, t0, t1, b1, b0, outward, side_color, bottom)
		if top_color.a > 0.0 and r_top > 0.0:
			tri(st, top_center, t0, t1, Vector3.UP, top_color, top_color, top_color)


## Vành đứng (ống ngắn) giữa hai bán kính, đa giác đều sides cạnh.
static func ring(st: SurfaceTool, center: Vector3, inner: float, outer: float, y0: float, y1: float, sides: int, side_color: Color, top_color: Color, yaw: float = 0.0) -> void:
	var bottom: Color = side_color.darkened(1.0 - BOTTOM_SHADE)
	for i: int in sides:
		var a0: float = yaw + TAU * float(i) / float(sides)
		var a1: float = yaw + TAU * float(i + 1) / float(sides)
		var d0: Vector3 = Vector3(cos(a0), 0.0, sin(a0))
		var d1: Vector3 = Vector3(cos(a1), 0.0, sin(a1))
		var c0: Vector3 = Vector3(center.x, 0.0, center.z)
		var o0: Vector3 = c0 + d0 * outer
		var o1: Vector3 = c0 + d1 * outer
		var i0: Vector3 = c0 + d0 * inner
		var i1: Vector3 = c0 + d1 * inner
		var up0: Vector3 = Vector3(0, y0, 0)
		var up1: Vector3 = Vector3(0, y1, 0)
		var outward: Vector3 = (d0 + d1).normalized()
		quad(st, o0 + up1, o1 + up1, o1 + up0, o0 + up0, outward, side_color, bottom)
		quad(st, i1 + up1, i0 + up1, i0 + up0, i1 + up0, -outward, side_color, bottom)
		quad(st, i0 + up1, o0 + up1, o1 + up1, i1 + up1, Vector3.UP, top_color, top_color)


## Nón (hoặc chóp) đứng: tâm đáy ở (center.x, y0, center.z), đỉnh ở y0 + height.
static func cone(st: SurfaceTool, center: Vector3, radius: float, y0: float, height: float, sides: int, color: Color) -> void:
	prism(st, center, radius, y0, y0 + height, sides, color, Color(0, 0, 0, 0), 0.0, 0.0)


## Gộp đã dựng thành mesh.
static func commit(st: SurfaceTool) -> ArrayMesh:
	return st.commit()
