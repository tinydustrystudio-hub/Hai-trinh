extends GutTest
## Bố cục Bến Bắc: đủ 10 bệ và 3 luồng, bệ không chồng nhau, không nằm trên luồng và đều có luồng trong tầm.

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


func test_counts() -> void:
	assert_eq(LAYOUT.pad_count(), 10)
	assert_eq(LAYOUT.lane_count(), 3)
	assert_eq(LAYOUT.lane_name_keys.size(), 3)


func test_pads_are_one_cell_apart() -> void:
	for i: int in LAYOUT.pad_count():
		for j: int in range(i + 1, LAYOUT.pad_count()):
			var d: float = LAYOUT.pad_positions[i].distance_to(LAYOUT.pad_positions[j])
			assert_gte(d, MapLayout.UNITS_PER_CELL, "bệ %d và %d quá gần" % [i, j])


func test_pads_do_not_block_lanes() -> void:
	for i: int in LAYOUT.pad_count():
		for lane: Lane in _lanes:
			var d: float = lane.distance_to(LAYOUT.pad_positions[i])
			assert_gt(d, TowerPad.RADIUS + Lane.RIBBON_WIDTH * 0.5, "bệ %d đè lên luồng %d" % [i, lane.lane_index])


func test_every_pad_reaches_a_lane() -> void:
	var reach: float = MIN_TOWER_RANGE_CELLS * MapLayout.UNITS_PER_CELL
	for i: int in LAYOUT.pad_count():
		var nearest: float = INF
		for lane: Lane in _lanes:
			nearest = minf(nearest, lane.distance_to(LAYOUT.pad_positions[i]))
		assert_lte(nearest, reach, "bệ %d không với tới luồng nào" % i)


func test_lanes_start_offshore_and_end_at_island() -> void:
	for lane: Lane in _lanes:
		var start: Vector3 = lane.position_at(0.0)
		var finish: Vector3 = lane.position_at(lane.length())
		assert_lt(start.z, -20.0, "luồng %d phải bắt đầu ngoài khơi" % lane.lane_index)
		var near_island: bool = false
		for block: AABB in LAYOUT.island_blocks:
			if block.grow(1.5).has_point(Vector3(finish.x, block.get_center().y, finish.z)):
				near_island = true
		assert_true(near_island, "luồng %d phải kết thúc ở đảo" % lane.lane_index)


func test_camera_start_inside_bounds() -> void:
	assert_true(LAYOUT.camera_bounds.has_point(LAYOUT.camera_start))
	assert_almost_eq(LAYOUT.camera_pitch_degrees, 55.0, 0.001)
