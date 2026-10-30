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
