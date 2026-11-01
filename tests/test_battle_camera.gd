extends GutTest
## Camera trận: giao tia với mặt nước, kẹp trong giới hạn, quán tính tắt dần.

func test_ray_hits_water_plane() -> void:
	var hit: Vector3 = BattleCamera.ray_to_plane(Vector3(0, 10, 0), Vector3(0, -1, -1).normalized(), 0.0)
	assert_almost_eq(hit, Vector3(0, 0, -10), Vector3.ONE * 0.001)


func test_ray_hits_raised_plane() -> void:
	var hit: Vector3 = BattleCamera.ray_to_plane(Vector3(2, 10, 0), Vector3(0, -1, 0), 0.5)
	assert_almost_eq(hit, Vector3(2, 0.5, 0), Vector3.ONE * 0.001)


func test_ray_pointing_up_returns_point_below_origin() -> void:
	var hit: Vector3 = BattleCamera.ray_to_plane(Vector3(1, 10, 3), Vector3(0, 1, 0), 0.0)
	assert_eq(hit, Vector3(1, 0, 3))


func test_clamp_focus() -> void:
	var area: Rect2 = Rect2(-10, -20, 20, 30)
	assert_eq(BattleCamera.clamp_focus(Vector2(0, 0), area), Vector2(0, 0))
	assert_eq(BattleCamera.clamp_focus(Vector2(50, -50), area), Vector2(10, -20))
	assert_eq(BattleCamera.clamp_focus(Vector2(-50, 50), area), Vector2(-10, 10))


func test_damping_decays_exponentially() -> void:
	var v: Vector2 = BattleCamera.apply_damping(Vector2(10, 0), 0.5, 2.0, 0.1)
	assert_almost_eq(v.x, 10.0 * exp(-1.0), 0.0001)


func test_damping_stops_when_slow() -> void:
	assert_eq(BattleCamera.apply_damping(Vector2(0.2, 0), 0.016, 6.0, 0.5), Vector2.ZERO)


func test_camera_pose_from_layout() -> void:
	var camera: BattleCamera = BattleCamera.new()
	var layout: MapLayout = MapLayout.new()
	layout.camera_bounds = Rect2(-10, -10, 20, 20)
	layout.camera_start = Vector2(4, -6)
	layout.camera_distance = 50.0
	layout.camera_pitch_degrees = 55.0
	camera.configure(layout)
	assert_almost_eq(camera.rotation_degrees.x, -55.0, 0.001)
	assert_almost_eq(camera.rotation_degrees.y, 0.0, 0.001)
	# Tia giữa camera phải rơi đúng vào điểm nhìn.
	var forward: Vector3 = -camera.transform.basis.z
	var hit: Vector3 = BattleCamera.ray_to_plane(camera.position, forward, 0.0)
	assert_almost_eq(hit, Vector3(4, 0, -6), Vector3.ONE * 0.001)
	camera.free()


func test_inertia_stops_at_bounds() -> void:
	var camera: BattleCamera = BattleCamera.new()
	camera.bounds = Rect2(-10, -10, 20, 20)
	camera.set_focus(Vector2(9, 0))
	camera.velocity = Vector2(100, 0)
	camera.step_inertia(0.1)
	assert_eq(camera.focus.x, 10.0)
	assert_eq(camera.velocity.x, 0.0)
	camera.free()


func _zoom_camera() -> BattleCamera:
	var camera: BattleCamera = BattleCamera.new()
	var layout: MapLayout = MapLayout.new()
	layout.camera_bounds = Rect2(-10, -8, 20, 16)
	layout.camera_zoom_bounds = Rect2(-50, -40, 100, 80)
	layout.camera_start = Vector2.ZERO
	layout.camera_distance = 100.0
	layout.camera_min_distance = 40.0
	camera.configure(layout)
	return camera


func test_starts_zoomed_out() -> void:
	var camera: BattleCamera = _zoom_camera()
	assert_eq(camera.distance, 100.0)
	assert_eq(camera.zoom_level(), 0.0)
	assert_eq(camera.bounds, Rect2(-10, -8, 20, 16))
	camera.free()


func test_start_distance_between_limits() -> void:
	var layout: MapLayout = MapLayout.new()
	layout.camera_distance = 150.0
	layout.camera_min_distance = 46.0
	assert_eq(layout.start_distance(), 150.0, "0 = vào trận ở toàn cảnh")
	layout.camera_start_distance = 104.0
	assert_eq(layout.start_distance(), 104.0)
	layout.camera_start_distance = 400.0
	assert_eq(layout.start_distance(), 150.0)
	var camera: BattleCamera = BattleCamera.new()
	layout.camera_start_distance = 104.0
	camera.configure(layout)
	assert_eq(camera.distance, 104.0)
	assert_eq(camera.max_distance, 150.0)
	camera.free()


func test_zoom_is_clamped_to_limits() -> void:
	var camera: BattleCamera = _zoom_camera()
	camera.set_distance(10.0)
	assert_eq(camera.distance, 40.0, "không phóng to quá giới hạn")
	assert_eq(camera.zoom_level(), 1.0)
	camera.set_distance(500.0)
	assert_eq(camera.distance, 100.0, "không thu nhỏ quá toàn cảnh")
	assert_eq(camera.zoom_level(), 0.0)
	camera.free()


func test_zoom_widens_pan_bounds() -> void:
	var camera: BattleCamera = _zoom_camera()
	camera.set_distance(40.0)
	assert_eq(camera.bounds, Rect2(-50, -40, 100, 80))
	camera.set_distance(70.0)
	assert_almost_eq(camera.zoom_level(), 0.5, 0.0001)
	assert_eq(camera.bounds, Rect2(-30, -24, 60, 48))
	camera.free()


func test_zooming_out_pulls_focus_back_inside() -> void:
	var camera: BattleCamera = _zoom_camera()
	camera.set_distance(40.0)
	camera.set_focus(Vector2(45, 30))
	assert_eq(camera.focus, Vector2(45, 30))
	camera.set_distance(100.0)
	assert_eq(camera.focus, Vector2(10, 8))
	camera.free()


func test_zoom_keeps_pitch_and_looks_at_focus() -> void:
	var camera: BattleCamera = _zoom_camera()
	camera.set_distance(55.0)
	assert_almost_eq(camera.rotation_degrees.x, -55.0, 0.001)
	assert_almost_eq(camera.rotation_degrees.y, 0.0, 0.001)
	var hit: Vector3 = BattleCamera.ray_to_plane(camera.position, -camera.transform.basis.z, 0.0)
	assert_almost_eq(Vector2(hit.x, hit.z), camera.focus, Vector2.ONE * 0.001)
	camera.free()


func test_zoom_by_keeps_point_under_gesture() -> void:
	var camera: BattleCamera = add_child_autofree(_zoom_camera())
	camera.make_current()
	var screen: Vector2 = camera.get_viewport().get_visible_rect().size * Vector2(0.7, 0.4)
	var before: Vector3 = camera.ground_point(screen)
	camera.zoom_by(1.5, screen)
	var after: Vector3 = camera.ground_point(screen)
	assert_almost_eq(Vector2(after.x, after.z), Vector2(before.x, before.z), Vector2.ONE * 0.05)
	assert_almost_eq(camera.distance, 100.0 / 1.5, 0.001)


func test_layout_zoom_range() -> void:
	var layout: MapLayout = load("res://data/maps/north_dock_layout.tres")
	assert_lt(layout.camera_min_distance, layout.camera_distance)
	assert_true(layout.camera_zoom_bounds.encloses(layout.camera_bounds))


func test_full_zoom_out_sees_whole_battlefield() -> void:
	# Màn hình gốc 16:9: thu nhỏ hết cỡ thì thấy mọi bệ và cả bốn luồng (trừ điểm xuất phát ngay mép).
	var layout: MapLayout = load("res://data/maps/north_dock_layout.tres")
	var viewport: SubViewport = add_child_autofree(SubViewport.new())
	viewport.size = Vector2i(1920, 1080)
	var camera: BattleCamera = BattleCamera.new()
	viewport.add_child(camera)
	camera.configure(layout)
	camera.make_current()
	camera.set_distance(layout.camera_distance)
	var screen: Rect2 = Rect2(Vector2.ZERO, Vector2(viewport.size))
	var points: Array[Vector3] = []
	points.append_array(layout.pad_positions)
	for lane: PackedVector3Array in layout.lane_points:
		points.append_array(lane.slice(1))
	for point: Vector3 in points:
		assert_true(screen.has_point(camera.unproject_position(point)), "thấy %s" % point)
	# Điểm xuất phát nằm sát mép: địch đi vào từ mép màn hình.
	for lane: PackedVector3Array in layout.lane_points:
		var start: Vector2 = camera.unproject_position(lane[0])
		assert_true(screen.grow(screen.size.x * 0.06).has_point(start), "luồng bắt đầu sát mép %s" % lane[0])


func test_aspect_setup_keeps_horizontal_coverage_on_narrow_screens() -> void:
	# Người duyệt (1/11): web (laptop 4:3, 16:10) và điện thoại (20:9) phải trông giống nhau.
	var wide: Dictionary = BattleCamera.aspect_setup(20.0 / 9.0)
	assert_eq(wide["keep"], Camera3D.KEEP_HEIGHT)
	assert_eq(wide["fov"], BattleCamera.FIELD_OF_VIEW)
	var reference: Dictionary = BattleCamera.aspect_setup(16.0 / 9.0)
	assert_eq(reference["keep"], Camera3D.KEEP_HEIGHT)
	for aspect: float in [4.0 / 3.0, 16.0 / 10.0, 1.0]:
		var narrow: Dictionary = BattleCamera.aspect_setup(aspect)
		assert_eq(narrow["keep"], Camera3D.KEEP_WIDTH)
		# Bề ngang nhìn thấy bằng bề ngang ở 16:9 với góc dọc FIELD_OF_VIEW.
		var expected: float = 2.0 * atan(tan(deg_to_rad(BattleCamera.FIELD_OF_VIEW) * 0.5) * 16.0 / 9.0)
		assert_almost_eq(deg_to_rad(narrow["fov"]), expected, 0.0001)


func test_four_by_three_screen_sees_the_same_battlefield() -> void:
	var layout: MapLayout = load("res://data/maps/north_dock_layout.tres")
	for size: Vector2i in [Vector2i(1440, 1080), Vector2i(1920, 1200), Vector2i(2000, 896)]:
		var viewport: SubViewport = add_child_autofree(SubViewport.new())
		viewport.size = size
		var camera: BattleCamera = BattleCamera.new()
		viewport.add_child(camera)
		camera.configure(layout)
		camera.make_current()
		camera.set_distance(layout.camera_distance)
		var screen: Rect2 = Rect2(Vector2.ZERO, Vector2(size))
		for pad: Vector3 in layout.pad_positions:
			assert_true(screen.has_point(camera.unproject_position(pad)), "thấy bệ %s ở %s" % [pad, size])
		# Đảo chính vẫn ở giữa theo chiều ngang trên mọi tỉ lệ.
		var middle: Vector2 = camera.unproject_position(layout.fortress_center)
		assert_almost_eq(middle.x, float(size.x) * 0.5, 2.0)
