extends GutTest
## Pool địch: tạo sẵn 80 con, lấy ra trả lại đúng, hạ thì báo enemy_killed, lọt thì báo enemy_leaked.

const SKIFF: EnemyData = preload("res://data/enemies/raider_skiff.tres")
const RAM: EnemyData = preload("res://data/enemies/ram_drone.tres")

var _pool: EnemyPool
var _lane: Lane


func before_each() -> void:
	_lane = Lane.new()
	_lane.setup(0, PackedVector3Array([Vector3(0, 0, -10), Vector3(0, 0, 0)]), &"LANE_NORTH")
	add_child_autofree(_lane)
	_pool = add_child_autofree(EnemyPool.new())
	watch_signals(Events)


func test_prebuilds_eighty() -> void:
	assert_eq(_pool.free_count(), 80)
	assert_eq(_pool.active_count(), 0)


func test_acquire_and_release() -> void:
	var enemy: Enemy = _pool.acquire(SKIFF, _lane)
	assert_not_null(enemy)
	assert_true(enemy.visible)
	assert_eq(_pool.active_count(), 1)
	assert_eq(_pool.free_count(), 79)
	_pool.release(enemy)
	assert_false(enemy.visible)
	assert_eq(_pool.active_count(), 0)
	assert_eq(_pool.free_count(), 80)


func test_runs_out_after_eighty() -> void:
	for i: int in 80:
		assert_not_null(_pool.acquire(SKIFF, _lane))
	assert_null(_pool.acquire(SKIFF, _lane))
	assert_engine_error(1)
	_pool.clear()
	assert_eq(_pool.free_count(), 80)


func test_kill_reports_reward() -> void:
	var enemy: Enemy = _pool.acquire(SKIFF, _lane)
	_pool.damage(enemy, 1000.0)
	assert_signal_emitted_with_parameters(Events, "enemy_killed", [enemy, 5])
	assert_eq(_pool.active_count(), 0)


func test_leak_reports_buoyancy_damage() -> void:
	var enemy: Enemy = _pool.acquire(RAM, _lane)
	# 10 đơn vị ở 1,5 ô/giây = 6 đơn vị/giây.
	_pool.advance(1.0)
	assert_signal_not_emitted(Events, "enemy_leaked")
	_pool.advance(1.0)
	assert_signal_emitted_with_parameters(Events, "enemy_leaked", [enemy, 3])
	assert_eq(_pool.active_count(), 0)


func test_wake_bends_along_the_path_behind_a_turning_boat() -> void:
	var bend: Lane = Lane.new()
	bend.setup(1, PackedVector3Array([Vector3(0, 0, -40), Vector3(0, 0, -20), Vector3(20, 0, -20)]), &"LANE_EAST")
	add_child_autofree(bend)
	var enemy: Enemy = _pool.acquire(SKIFF, bend, 30.0)
	enemy.lateral_offset = 0.0
	_pool.advance(0.01)
	assert_eq(_pool.get_node("Wakes").multimesh.visible_instance_count, 1)
	var length: float = SKIFF.size_cells * MapLayout.UNITS_PER_CELL
	var stern: float = length * 0.45
	var wake_length: float = length * EnemyPool.WAKE_LENGTH
	var yaw: Basis = Basis.looking_at(enemy.forward, Vector3.UP)
	var back: Vector3 = bend.direction_at(enemy.distance - stern - wake_length)
	var curvature: float = EnemyPool.wake_curvature(yaw, back, wake_length)
	assert_ne(curvature, 0.0, "tàu đang ở khúc quanh: vệt phải cong")
	var origin: Vector3 = Vector3(enemy.position.x, 0.0, enemy.position.z) - enemy.forward * stern
	for k: int in 5:
		var s: float = wake_length * float(k) / 4.0
		var local: Vector3 = EnemyPool.wake_point(curvature, s, 0.0)
		var world: Vector3 = origin + yaw * local
		# Đường giữa vệt bám theo đường tàu đã đi.
		assert_lt(bend.distance_to(world), 0.6, "điểm %d của vệt lệch khỏi đường đi" % k)


func test_wake_is_straight_on_a_straight_lane() -> void:
	var yaw: Basis = Basis.looking_at(Vector3(0, 0, 1), Vector3.UP)
	assert_almost_eq(EnemyPool.wake_curvature(yaw, Vector3(0, 0, 1), 8.0), 0.0, 0.0001)
	assert_almost_eq(EnemyPool.wake_point(0.0, 5.0, 0.0), Vector3(0, 0, 5), Vector3.ONE * 0.0001)
	assert_almost_eq(EnemyPool.wake_point(0.0, 5.0, 1.0), Vector3(1, 0, 5), Vector3.ONE * 0.0001)


func test_wake_point_is_smooth_through_straight_threshold() -> void:
	var a: Vector3 = EnemyPool.wake_point(EnemyPool.WAKE_STRAIGHT * 0.99, 8.0, 0.5)
	var b: Vector3 = EnemyPool.wake_point(EnemyPool.WAKE_STRAIGHT * 1.01, 8.0, 0.5)
	assert_almost_eq(a, b, Vector3.ONE * 0.001)


func test_wake_is_short_right_after_spawn() -> void:
	var enemy: Enemy = _pool.acquire(SKIFF, _lane)
	_pool.advance(0.01)
	assert_eq(_pool.get_node("Wakes").multimesh.visible_instance_count, 0)
	assert_not_null(enemy)
