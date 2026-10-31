extends GutTest
## Luồng: chiều dài, vị trí theo quãng đường, hướng đi và khoảng cách tới luồng.

var _lane: Lane


func before_each() -> void:
	_lane = Lane.new()
	_lane.setup(0, PackedVector3Array([Vector3(0, 0, -20), Vector3(0, 0, 0)]), &"LANE_NORTH")


func after_each() -> void:
	_lane.free()


func test_straight_lane_length() -> void:
	assert_almost_eq(_lane.length(), 20.0, 0.05)


func test_position_at_distance() -> void:
	assert_almost_eq(_lane.position_at(0.0), Vector3(0, 0, -20), Vector3.ONE * 0.01)
	assert_almost_eq(_lane.position_at(5.0), Vector3(0, 0, -15), Vector3.ONE * 0.05)
	assert_almost_eq(_lane.position_at(20.0), Vector3(0, 0, 0), Vector3.ONE * 0.05)


func test_position_is_clamped() -> void:
	assert_almost_eq(_lane.position_at(-3.0), Vector3(0, 0, -20), Vector3.ONE * 0.01)
	assert_almost_eq(_lane.position_at(999.0), Vector3(0, 0, 0), Vector3.ONE * 0.05)


func test_direction_points_toward_end() -> void:
	assert_almost_eq(_lane.direction_at(10.0), Vector3(0, 0, 1), Vector3.ONE * 0.01)
	assert_almost_eq(_lane.direction_at(20.0), Vector3(0, 0, 1), Vector3.ONE * 0.01)


func test_distance_ignores_height() -> void:
	assert_almost_eq(_lane.distance_to(Vector3(3, 5, -10)), 3.0, 0.01)


func test_curve_passes_through_points() -> void:
	var points: PackedVector3Array = PackedVector3Array([Vector3(0, 0, 0), Vector3(10, 0, 5), Vector3(20, 0, 0)])
	var curve: Curve3D = Lane.build_curve(points)
	assert_eq(curve.point_count, 3)
	for i: int in points.size():
		assert_eq(curve.get_point_position(i), points[i])
	assert_eq(curve.get_point_in(0), Vector3.ZERO)
	assert_eq(curve.get_point_out(1), (points[2] - points[0]) * Lane.SMOOTHNESS)


func test_reveal_strength_curve() -> void:
	assert_almost_eq(Lane.reveal_strength(0.0), Lane.IDLE_STRENGTH, 0.0001)
	assert_almost_eq(Lane.reveal_strength(Lane.REVEAL_SECONDS + Lane.FADE_SECONDS), 1.0, 0.0001)
	assert_almost_eq(Lane.reveal_strength(Lane.FADE_SECONDS), 1.0, 0.0001)
	assert_almost_eq(Lane.reveal_strength(Lane.FADE_SECONDS * 0.5), lerpf(Lane.IDLE_STRENGTH, 1.0, 0.5), 0.0001)


func test_lane_is_faint_until_revealed_then_fades() -> void:
	assert_almost_eq(_lane.strength(), Lane.IDLE_STRENGTH, 0.0001)
	_lane.reveal()
	assert_almost_eq(_lane.strength(), 1.0, 0.0001)
	_lane._process(Lane.REVEAL_SECONDS)
	assert_almost_eq(_lane.strength(), 1.0, 0.0001, "vẫn rõ trong lúc báo đợt")
	_lane._process(Lane.FADE_SECONDS)
	assert_almost_eq(_lane.strength(), Lane.IDLE_STRENGTH, 0.0001, "mờ lại sau vài giây")
