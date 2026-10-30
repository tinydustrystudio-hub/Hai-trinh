class_name EnemyMeshes
extends RefCounted
## Dựng mesh khối thô cho từng loại địch, tô màu bằng màu đỉnh để cả thân lẫn điểm nhấn chỉ tốn
## một lệnh vẽ. Mesh được lưu theo EnemyData, mọi con cùng loại dùng chung.

static var _cache: Dictionary[EnemyData, ArrayMesh] = {}
static var _material: StandardMaterial3D


static func mesh_for(data: EnemyData) -> ArrayMesh:
	if not _cache.has(data):
		_cache[data] = build(data)
	return _cache[data]


## Vật liệu dùng chung cho mọi địch (màu lấy từ màu đỉnh).
static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.roughness = 0.7
	return _material


## Mũi tàu hướng về −Z (hướng nhìn mặc định của Node3D), gốc ở mực nước.
static func build(data: EnemyData) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var length: float = data.size_cells * MapLayout.UNITS_PER_CELL
	var body: Color = data.body_color
	var accent: Color = data.accent_color
	match data.hull:
		EnemyData.Hull.SKIFF:
			# Xuồng hở: thân thấp, mạn ốp tấm sắt, buồng lái nhỏ phía sau, sọc vàng ở mũi.
			_box(st, Vector3(0, 0.15, 0), Vector3(length * 0.42, 0.5, length), body)
			_box(st, Vector3(0, 0.55, length * 0.25), Vector3(length * 0.3, 0.45, length * 0.25), body.lightened(0.25))
			_box(st, Vector3(0, 0.42, -length * 0.42), Vector3(length * 0.43, 0.08, length * 0.12), accent)
		EnemyData.Hull.RAM:
			# Ca nô cảm tử: thân hẹp và dài, bó thuốc nổ ở mũi, cột ăng-ten đèn đỏ.
			_box(st, Vector3(0, 0.12, 0.1 * length), Vector3(length * 0.28, 0.4, length * 0.8), body)
			_box(st, Vector3(0, 0.12, -length * 0.38), Vector3(length * 0.18, 0.3, length * 0.2), body)
			_box(st, Vector3(0, 0.45, -length * 0.3), Vector3(length * 0.3, 0.3, length * 0.18), accent)
			_box(st, Vector3(0, 0.75, length * 0.3), Vector3(0.08, 0.7, 0.08), accent)
		EnemyData.Hull.CRAB:
			# Cua giáp gai: mai rộng và dẹt, gai và khớp phát sáng lam ngọc, càng hai bên.
			var width: float = length * 1.2
			_box(st, Vector3(0, 0.35, 0), Vector3(width * 0.8, 0.8, length * 0.8), body)
			for i: int in 3:
				var z: float = (float(i) - 1.0) * length * 0.25
				_box(st, Vector3(0, 0.95, z), Vector3(0.35, 0.5, 0.35), accent)
				_box(st, Vector3(-width * 0.5, 0.1, z), Vector3(width * 0.25, 0.2, 0.25), body.darkened(0.2))
				_box(st, Vector3(width * 0.5, 0.1, z), Vector3(width * 0.25, 0.2, 0.25), body.darkened(0.2))
			_box(st, Vector3(-width * 0.3, 0.3, -length * 0.5), Vector3(0.6, 0.4, 0.9), accent)
			_box(st, Vector3(width * 0.3, 0.3, -length * 0.5), Vector3(0.6, 0.4, 0.9), accent)
	return st.commit()


static func _box(st: SurfaceTool, center: Vector3, size: Vector3, color: Color) -> void:
	var h: Vector3 = size * 0.5
	# Mỗi mặt: pháp tuyến và 4 góc theo chiều kim đồng hồ khi nhìn từ ngoài (mặt trước của Godot).
	var faces: Array[Array] = [
		[Vector3.UP, [Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)]],
		[Vector3.DOWN, [Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, -h.y, -h.z), Vector3(-h.x, -h.y, -h.z)]],
		[Vector3.FORWARD, [Vector3(h.x, h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z)]],
		[Vector3.BACK, [Vector3(-h.x, h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z)]],
		[Vector3.LEFT, [Vector3(-h.x, h.y, -h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, -h.y, h.z), Vector3(-h.x, -h.y, -h.z)]],
		[Vector3.RIGHT, [Vector3(h.x, h.y, h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z)]],
	]
	for face: Array in faces:
		var normal: Vector3 = face[0]
		var c: Array = face[1]
		for index: int in [0, 1, 2, 0, 2, 3]:
			st.set_color(color)
			st.set_normal(normal)
			st.add_vertex(center + (c[index] as Vector3))
