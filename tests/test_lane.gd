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


func test_fade_toward() -> void:
	assert_almost_eq(Lane.fade_toward(0.0, true, Lane.FADE_IN_SECONDS * 0.5), 0.5, 0.0001)
	assert_almost_eq(Lane.fade_toward(0.0, true, 10.0), 1.0, 0.0001)
	assert_almost_eq(Lane.fade_toward(1.0, false, Lane.FADE_OUT_SECONDS * 0.5), 0.5, 0.0001)
	assert_almost_eq(Lane.fade_toward(1.0, false, 10.0), 0.0, 0.0001)


func test_lane_hidden_until_warning_then_hides_again() -> void:
	assert_eq(_lane.strength(), 0.0, "bình thường luồng ẩn")
	_lane.set_warning(true)
	_lane.advance_fade(Lane.FADE_IN_SECONDS)
	assert_almost_eq(_lane.strength(), 1.0, 0.0001)
	_lane.advance_fade(5.0)
	assert_almost_eq(_lane.strength(), 1.0, 0.0001, "rõ suốt lúc báo động")
	_lane.set_warning(false)
	_lane.advance_fade(Lane.FADE_OUT_SECONDS)
	assert_eq(_lane.strength(), 0.0, "tắt khi địch đã ra")
