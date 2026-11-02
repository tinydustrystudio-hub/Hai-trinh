extends GutTest
## Đảo dựng bằng code (GDD mục 8.6): pháo đài nhiều tầng có tháp cao, không phải một khối vuông;
## có bọt quanh chân đảo và bóng giả dời theo hướng ngược nắng.

const LAYOUT: MapLayout = preload("res://data/maps/north_dock_layout.tres")
## Bố cục có 4 đảo vệ tinh đậu cạnh đảo chính (màn thật chỉ có đảo đã mua).
var SATS: MapLayout = TestLayouts.with_satellites(4)


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
	var mesh: ArrayMesh = AllianceFortress.build_satellites(SATS)
	assert_gt(_triangles(mesh), 4 * 50)
	assert_eq(AllianceFortress.buoy_positions(LAYOUT).size(), 6)


func test_foam_rings_every_island() -> void:
	var mesh: ArrayMesh = Island.build_foam(SATS)
	var box: AABB = mesh.get_aabb()
	# Bọt bao trọn mọi đảo vệ tinh.
	for center: Vector3 in SATS.satellite_centers:
		assert_true(box.grow(0.01).has_point(Vector3(center.x, Island.FOAM_Y, center.z)))
	assert_gt(_triangles(mesh), 200)


func test_shadow_falls_away_from_sun() -> void:
	# Chỉ xét bóng của pháo đài: bỏ đảo vệ tinh (đặt lệch nhau) ra khỏi bố cục thử.
	var fortress_only: MapLayout = LAYOUT.duplicate()
	fortress_only.satellite_centers = PackedVector3Array()
	fortress_only.platform_centers = PackedVector3Array()
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


func test_lane_beacons_point_to_each_lane() -> void:
	var layout: MapLayout = load("res://data/maps/north_dock_layout.tres")
	var expected: Array[Vector3] = [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1)]
	var used: PackedVector3Array = PackedVector3Array()
	for i: int in layout.lane_count():
		var at: Vector3 = LaneBeacons.beacon_position(layout, i)
		var end: Vector3 = layout.lane_points[i][layout.lane_points[i].size() - 1]
		assert_lt(at.distance_to(end), 3.0, "đèn %d đứng chỗ luồng cập đảo" % i)
		assert_lt(at.distance_to(layout.fortress_center), layout.fortress_radius, "đèn %d nằm trên pháo đài" % i)
		assert_false(used.has(at), "mỗi luồng một đèn riêng")
		used.append(at)
		assert_gt(LaneBeacons.incoming_direction(layout, i).dot(expected[i]), 0.9, "vệt sáng của đèn %d chỉ đúng phía" % i)


func test_lane_beacons_toggle() -> void:
	var island: Island = add_child_autofree(Island.new())
	island.build(load("res://data/maps/north_dock_layout.tres"))
	assert_eq(island.beacons.active_count(), 0)
	island.set_lane_warning(2, true)
	assert_true(island.beacons.is_active(2))
	assert_eq(island.beacons.active_count(), 1)
	island.set_lane_warning(2, false)
	island.set_lane_warning(9, true)
	assert_eq(island.beacons.active_count(), 0)


func test_bob_gain_smaller_for_bigger_islands() -> void:
	# Góp ý 4: đảo càng to càng ít dập dìu.
	assert_almost_eq(Island.bob_gain(Island.REFERENCE_RADIUS), 1.0, 0.0001)
	assert_lt(Island.bob_gain(LAYOUT.fortress_radius), Island.bob_gain(LAYOUT.satellite_radius))
	assert_lt(Island.bob_gain(LAYOUT.fortress_radius), 0.35)
	assert_lte(Island.bob_gain(0.5), 1.0)


func test_bob_pose_is_gentle_and_scales_with_size() -> void:
	var ocean: Ocean = add_child_autofree(Ocean.new())
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 9
	var max_small: float = 0.0
	var max_big: float = 0.0
	for i: int in 200:
		var at: Vector3 = Vector3(rng.randf_range(-60, 60), 0, rng.randf_range(-60, 60))
		var t: float = rng.randf_range(0, 120)
		var small: Vector3 = Island.sample_pose(ocean, at, LAYOUT.satellite_radius, t)
		var big: Vector3 = Island.sample_pose(ocean, at, LAYOUT.fortress_radius, t)
		max_small = maxf(max_small, absf(small.x))
		max_big = maxf(max_big, absf(big.x))
		assert_lte(absf(small.y), Island.MAX_ROCK_DEGREES)
		assert_lte(absf(small.z), Island.MAX_ROCK_DEGREES)
	assert_gt(max_small, 0.02, "đảo nhỏ có dập dìu")
	assert_lt(max_small, 0.25, "nhưng chỉ nhẹ")
	assert_lt(max_big, max_small * 0.5, "đảo to dập dìu ít hơn hẳn")


func test_island_bob_moves_satellites_and_keeps_tilt() -> void:
	var ocean: Ocean = add_child_autofree(Ocean.new())
	var island: Island = add_child_autofree(Island.new())
	island.build(SATS)
	assert_eq(island.satellites.size(), SATS.satellite_centers.size())
	island.set_tilt(5.0)
	var moved: bool = false
	for t: float in [1.0, 3.7, 8.2, 15.5]:
		island.bob(ocean, t)
		for k: int in island.satellites.size():
			if absf(island.satellites[k].position.y) > 0.001:
				moved = true
	assert_true(moved)
	assert_almost_eq(island.tilt_degrees(), 5.0, 0.0001, "nghiêng theo Độ Nổi vẫn giữ")


func test_satellite_pads_follow_their_island() -> void:
	var island: Island = add_child_autofree(Island.new())
	island.build(SATS)
	for pad: TowerPad in island.pads:
		var k: int = SATS.satellite_index_of_pad(pad.pad_index)
		if k >= 0:
			assert_eq(pad.get_parent(), island.satellites[k])
			assert_almost_eq(pad.position.length(), 0.0, 0.01, "bệ ở tâm đảo vệ tinh")
