extends GutTest
## Bố cục Bến Bắc theo GDD mục 8.6: đảo chính ở giữa, 4 luồng từ 4 phía, 10 bệ xếp hai vòng
## (6 trên mỏm bến, 4 trên đảo vệ tinh); bệ không chồng nhau, không đè luồng và đều có luồng trong tầm.

const LAYOUT: MapLayout = preload("res://data/maps/north_dock_layout.tres")
## Tầm cấp 1 nhỏ nhất ở Phần 3 GDD là 2,5 ô (Lô Cốt Keo).
const MIN_TOWER_RANGE_CELLS: float = 2.5

var _lanes: Array[Lane] = []


func before_all() -> void:
	for i: int in LAYOUT.lane_count():
		var lane: Lane = Lane.new()
		lane.setup(i, LAYOUT.lane_points[i], LAYOUT.lane_name_keys[i])
		_lanes.append(lane)


func after_all() -> void:
	for lane: Lane in _lanes:
		lane.free()
	_lanes.clear()


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func test_counts() -> void:
	assert_eq(LAYOUT.pad_count(), 10)
	assert_eq(LAYOUT.lane_count(), 4)
	assert_eq(LAYOUT.lane_name_keys, [&"LANE_NORTH", &"LANE_EAST", &"LANE_WEST", &"LANE_SOUTH"] as Array[StringName])
	assert_eq(LAYOUT.satellite_centers.size(), 4)


func test_two_rings_of_pads() -> void:
	var on_piers: int = 0
	var on_satellites: int = 0
	for i: int in LAYOUT.pad_count():
		var d: float = _flat_distance(LAYOUT.pad_positions[i], LAYOUT.fortress_center)
		if LAYOUT.is_satellite_pad(i):
			on_satellites += 1
			assert_gt(d, LAYOUT.fortress_radius * 2.0, "bệ %d: đảo vệ tinh ở vòng ngoài" % i)
		else:
			on_piers += 1
			assert_between(d, LAYOUT.fortress_radius, LAYOUT.fortress_radius + MapLayout.UNITS_PER_CELL * 2.0, "bệ %d: trên mỏm bến" % i)
	assert_eq(on_piers, 6)
	assert_eq(on_satellites, 4)


func test_satellite_size() -> void:
	# Đường kính 2 ô (GDD mục 5.4).
	assert_almost_eq(LAYOUT.satellite_radius * 2.0 / MapLayout.UNITS_PER_CELL, 2.0, 0.01)


func test_pads_are_one_cell_apart() -> void:
	for i: int in LAYOUT.pad_count():
		for j: int in range(i + 1, LAYOUT.pad_count()):
			var d: float = LAYOUT.pad_positions[i].distance_to(LAYOUT.pad_positions[j])
			assert_gte(d, MapLayout.UNITS_PER_CELL, "bệ %d và %d quá gần" % [i, j])


func test_pads_and_islands_do_not_block_lanes() -> void:
	for i: int in LAYOUT.pad_count():
		var footprint: float = LAYOUT.satellite_radius if LAYOUT.is_satellite_pad(i) else AllianceFortress.PIER_END_RADIUS
		for lane: Lane in _lanes:
			var d: float = lane.distance_to(LAYOUT.pad_positions[i])
			assert_gt(d, footprint + Lane.RIBBON_WIDTH * 0.5, "bệ %d đè lên luồng %d" % [i, lane.lane_index])


func test_every_pad_reaches_a_lane() -> void:
	var reach: float = MIN_TOWER_RANGE_CELLS * MapLayout.UNITS_PER_CELL
	for i: int in LAYOUT.pad_count():
		var nearest: float = INF
		for lane: Lane in _lanes:
			nearest = minf(nearest, lane.distance_to(LAYOUT.pad_positions[i]))
		assert_lte(nearest, reach, "bệ %d không với tới luồng nào" % i)


func test_lanes_come_from_four_sides() -> void:
	# Bắc (−z), Đông (+x), Tây (−x), Nam (+z).
	var expected: Array[Vector2] = [Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1)]
	for lane: Lane in _lanes:
		var start: Vector3 = lane.position_at(0.0) - LAYOUT.fortress_center
		var dir: Vector2 = Vector2(start.x, start.z).normalized()
		assert_gt(dir.dot(expected[lane.lane_index]), 0.9, "luồng %d phải bắt đầu ở đúng phía" % lane.lane_index)
		assert_gt(Vector2(start.x, start.z).length(), LAYOUT.fortress_radius * 4.0, "luồng %d phải bắt đầu từ mép chiến trường" % lane.lane_index)


func test_lanes_end_at_fortress_without_cutting_through() -> void:
	for lane: Lane in _lanes:
		var finish: Vector3 = lane.position_at(lane.length())
		assert_almost_eq(_flat_distance(finish, LAYOUT.fortress_center), LAYOUT.fortress_radius, 1.5, "luồng %d phải cập đê chắn sóng" % lane.lane_index)
		var steps: int = 100
		for k: int in steps - 10:
			var p: Vector3 = lane.position_at(lane.length() * float(k) / float(steps))
			assert_gt(_flat_distance(p, LAYOUT.fortress_center), LAYOUT.fortress_radius + 2.0, "luồng %d cắt qua pháo đài" % lane.lane_index)


func test_camera_looks_at_island_and_pans_only_a_little() -> void:
	assert_eq(LAYOUT.camera_start, Vector2(LAYOUT.fortress_center.x, LAYOUT.fortress_center.z))
	assert_true(LAYOUT.camera_bounds.has_point(LAYOUT.camera_start))
	assert_lte(LAYOUT.camera_bounds.size.x, LAYOUT.fortress_radius * 2.0, "chỉ kéo trượt nhẹ")
	assert_lte(LAYOUT.camera_bounds.size.y, LAYOUT.fortress_radius * 2.0, "chỉ kéo trượt nhẹ")
	assert_almost_eq(LAYOUT.camera_pitch_degrees, 55.0, 0.001)


func test_four_lanes_are_balanced_and_long() -> void:
	# Góp ý 3 của đạo diễn: bốn phía cân bằng như nhau, đường đi dài hơn bản đầu (dài nhất khoảng 18 ô).
	var shortest: float = INF
	var longest: float = 0.0
	for lane: Lane in _lanes:
		shortest = minf(shortest, lane.length())
		longest = maxf(longest, lane.length())
	assert_gte(shortest / MapLayout.UNITS_PER_CELL, 30.0, "luồng ngắn nhất phải từ 30 ô")
	assert_lte(longest / shortest, 1.03, "bốn luồng dài gần bằng nhau")


func test_one_satellite_per_lane() -> void:
	for lane: Lane in _lanes:
		var nearest: float = INF
		for center: Vector3 in LAYOUT.satellite_centers:
			nearest = minf(nearest, lane.distance_to(center))
		assert_lte(nearest, MIN_TOWER_RANGE_CELLS * MapLayout.UNITS_PER_CELL, "luồng %d có đảo vệ tinh canh" % lane.lane_index)


func test_satellite_counts_follow_level_rules() -> void:
	# GDD mục 5.4: màn 1 cấp sẵn 4 đảo, đặt tối đa 8; các đảo cấp sẵn nằm trong bố cục.
	assert_eq(LAYOUT.free_satellites(), 4)
	assert_eq(LAYOUT.satellite_max_count, 8)
	assert_eq(LAYOUT.extra_satellites(), 4)
	assert_gte(LAYOUT.satellite_centers.size(), LAYOUT.free_satellites())
	assert_lte(LAYOUT.free_satellites(), LAYOUT.satellite_max_count)
	var open_layout: MapLayout = MapLayout.new()
	open_layout.satellite_centers = PackedVector3Array([Vector3.ZERO, Vector3(1, 0, 1)])
	assert_eq(open_layout.free_satellites(), 2, "không khai báo thì dùng số đảo đã đặt")
	open_layout.satellite_max_count = 1
	assert_eq(open_layout.extra_satellites(), 0)
