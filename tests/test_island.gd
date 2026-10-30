extends GutTest
## Đảo dựng bằng code (GDD mục 8.6): pháo đài nhiều tầng có tháp cao, không phải một khối vuông;
## có bọt quanh chân đảo và bóng giả dời theo hướng ngược nắng.

const LAYOUT: MapLayout = preload("res://data/maps/north_dock_layout.tres")


func _triangles(mesh: ArrayMesh) -> int:
	var total: int = 0
	for s: int in mesh.get_surface_count():
		total += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return total


func test_fortress_has_tiers_and_tower() -> void:
	var mesh: ArrayMesh = AllianceFortress.build_fortress(LAYOUT)
	var box: AABB = mesh.get_aabb()
	# Mỏm bến vươn ra tới bệ; tháp hải đăng cao gần bằng bán kính pháo đài.
	assert_gt(box.size.x, LAYOUT.fortress_radius * 2.4)
	assert_gt(box.end.y, LAYOUT.fortress_radius * 0.8)
	assert_gt(_triangles(mesh), 2000, "đủ chi tiết, không phải vài khối")
	# Nhiều tầng: có mặt sàn ở ít nhất ba độ cao khác nhau quanh tâm.
	var heights: Dictionary = {}
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	for i: int in vertices.size():
		if normals[i].y > 0.99 and Vector2(vertices[i].x, vertices[i].z).length() < LAYOUT.fortress_radius:
			heights[snappedf(vertices[i].y, 0.5)] = true
	assert_gte(heights.size(), 3, "phải thấy rõ các tầng")


func test_lamp_sits_on_tower() -> void:
	var lamp: AABB = AllianceFortress.build_lamp(LAYOUT).get_aabb()
	assert_gt(lamp.position.y, AllianceFortress.tower_top(LAYOUT.fortress_radius))


func test_satellites_and_buoys() -> void:
	var mesh: ArrayMesh = AllianceFortress.build_satellites(LAYOUT)
	assert_gt(_triangles(mesh), 4 * 50)
	assert_eq(AllianceFortress.buoy_positions(LAYOUT).size(), 6)


func test_foam_rings_every_island() -> void:
	var mesh: ArrayMesh = Island.build_foam(LAYOUT)
	var box: AABB = mesh.get_aabb()
	# Bọt bao trọn mọi đảo vệ tinh.
	for center: Vector3 in LAYOUT.satellite_centers:
		assert_true(box.grow(0.01).has_point(Vector3(center.x, Island.FOAM_Y, center.z)))
	assert_gt(_triangles(mesh), 200)


func test_shadow_falls_away_from_sun() -> void:
	# Chỉ xét bóng của pháo đài: bỏ đảo vệ tinh (đặt lệch nhau) ra khỏi bố cục thử.
	var fortress_only: MapLayout = LAYOUT.duplicate()
	fortress_only.satellite_centers = PackedVector3Array()
	var box: AABB = Island.build_shadow(fortress_only).get_aabb()
	var sun: Vector3 = LAYOUT.sun_direction
	# Bóng của pháo đài lệch về phía ngược nắng so với tâm đảo.
	var center: Vector3 = box.get_center()
	var shifted: Vector2 = Vector2(center.x - LAYOUT.fortress_center.x, center.z - LAYOUT.fortress_center.z)
	assert_lt(shifted.dot(Vector2(sun.x, sun.z)), 0.0)


func test_tilt_moves_fortress_only() -> void:
	var island: Island = add_child_autofree(load("res://battle/map/island.tscn").instantiate())
	island.build(LAYOUT)
	island.set_tilt(5.0)
	assert_almost_eq(island.tilt_degrees(), 5.0, 0.0001)
	assert_eq(island.pads.size(), 10)
