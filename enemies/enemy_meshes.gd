class_name EnemyMeshes
extends RefCounted
## Dựng mesh khối thô cho từng loại địch, tô màu bằng màu đỉnh để cả thân lẫn điểm nhấn chỉ tốn
## một lệnh vẽ. Mesh được lưu theo EnemyData, mọi con cùng loại dùng chung.

static var _cache: Dictionary[EnemyData, ArrayMesh] = {}
static var _material: StandardMaterial3D


static func mesh_for(data: EnemyData) -> ArrayMesh:
	if not _cache.has(data):
		var model: ArrayMesh = model_mesh(data)
		_cache[data] = model if model != null else build(data)
	return _cache[data]


## Mesh lấy từ assets/models/enm_<id>.glb (dựng bằng Blender, màu đỉnh đã nướng sẵn), hoặc null nếu chưa có mô hình.
static func model_mesh(data: EnemyData) -> ArrayMesh:
	return ModelMesh.load_mesh("enm_%s" % String(data.id))


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
			# Xuồng cướp: thân thuyền thon, mũi nhọn có răng vàng, mạn ốp sắt, buồng lái và cờ phía sau.
			_box(st, Vector3(0, 0.15, length * 0.1), Vector3(length * 0.46, 0.5, length * 0.8), body)
			_box(st, Vector3(0, 0.1, -length * 0.42), Vector3(length * 0.28, 0.36, length * 0.22), body)
			_box(st, Vector3(0, 0.05, -length * 0.55), Vector3(length * 0.12, 0.2, length * 0.14), body.darkened(0.2))
			_box(st, Vector3(0, 0.45, -length * 0.42), Vector3(length * 0.3, 0.08, length * 0.16), accent)
			for x: float in [-1.0, 1.0]:
				_box(st, Vector3(x * length * 0.25, 0.48, length * 0.05), Vector3(0.1, 0.18, length * 0.55), body.lightened(0.2))
			_box(st, Vector3(0, 0.62, length * 0.32), Vector3(length * 0.32, 0.5, length * 0.24), body.lightened(0.3))
			_box(st, Vector3(0, 1.1, length * 0.38), Vector3(0.07, 0.9, 0.07), body.darkened(0.3))
			_box(st, Vector3(0, 1.35, length * 0.32), Vector3(0.04, 0.35, 0.4), accent)
		EnemyData.Hull.RAM:
			# Ca nô cảm tử: thân hẹp dài như mũi tên, ba thùng thuốc nổ ở mũi, động cơ đuôi, ăng-ten đèn đỏ cao.
			_box(st, Vector3(0, 0.12, length * 0.12), Vector3(length * 0.26, 0.38, length * 0.72), body)
			_box(st, Vector3(0, 0.1, -length * 0.4), Vector3(length * 0.16, 0.3, length * 0.2), body)
			for i: int in 3:
				var dz: float = -length * (0.18 + 0.09 * float(i))
				_box(st, Vector3(0, 0.55 + 0.02 * float(i), dz), Vector3(length * 0.34, 0.34, length * 0.08), accent)
			_box(st, Vector3(0, 0.26, length * 0.5), Vector3(length * 0.3, 0.3, length * 0.12), body.darkened(0.3))
			_box(st, Vector3(0, 0.95, length * 0.32), Vector3(0.08, 1.0, 0.08), accent)
			_box(st, Vector3(0, 1.5, length * 0.32), Vector3(0.22, 0.22, 0.22), accent.lightened(0.3))
		EnemyData.Hull.CRAB:
			# Cua giáp gai: mai rộng, hàng gai lam ngọc, 3 chân mỗi bên, hai càng to phía trước, hai mắt trên cuống.
			var width: float = length * 1.2
			_box(st, Vector3(0, 0.4, 0), Vector3(width * 0.7, 0.8, length * 0.75), body)
			_box(st, Vector3(0, 0.85, 0), Vector3(width * 0.5, 0.2, length * 0.55), body.lightened(0.15))
			for i: int in 3:
				var z: float = (float(i) - 1.0) * length * 0.25
				_box(st, Vector3(0, 1.1, z), Vector3(0.3, 0.55, 0.3), accent)
				for x: float in [-1.0, 1.0]:
					_box(st, Vector3(x * width * 0.46, 0.15, z), Vector3(width * 0.3, 0.16, 0.2), body.darkened(0.25))
			for x: float in [-1.0, 1.0]:
				_box(st, Vector3(x * width * 0.28, 0.4, -length * 0.5), Vector3(0.28, 0.28, length * 0.28), body.darkened(0.1))
				_box(st, Vector3(x * width * 0.32, 0.45, -length * 0.78), Vector3(width * 0.2, 0.4, length * 0.3), accent)
				_box(st, Vector3(x * 0.2, 1.0, -length * 0.36), Vector3(0.1, 0.35, 0.1), body.darkened(0.3))
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
