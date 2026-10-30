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
