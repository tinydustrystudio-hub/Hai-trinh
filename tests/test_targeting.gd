extends GutTest
## Chọn mục tiêu: đúng tầng, trong tầm, đi xa nhất trên luồng; tìm lại 5 lần mỗi giây.

const SKIFF: EnemyData = preload("res://data/enemies/raider_skiff.tres")

var _pool: EnemyPool
var _lane: Lane
var _surface: Array[EnemyData.Layer] = [EnemyData.Layer.SURFACE]


func before_each() -> void:
	_lane = Lane.new()
	_lane.setup(0, PackedVector3Array([Vector3(-40, 0, 0), Vector3(40, 0, 0)]), &"LANE_EAST")
	add_child_autofree(_lane)
	_pool = add_child_autofree(EnemyPool.new())


func test_picks_furthest_along_lane_in_range() -> void:
	var behind: Enemy = _pool.acquire(SKIFF, _lane, 36.0)
	var ahead: Enemy = _pool.acquire(SKIFF, _lane, 44.0)
	_pool.acquire(SKIFF, _lane, 70.0)
	# Lô cốt ở (0, 0, 4), tầm 12: con ở x = 30 ngoài tầm dù đi xa nhất.
	var picked: Enemy = Targeting.pick(_pool.active, Vector3(0, 0, 4), 12.0, _surface)
	assert_eq(picked, ahead)
	assert_ne(picked, behind)


func test_wrong_layer_is_ignored() -> void:
	_pool.acquire(SKIFF, _lane, 40.0)
	var air_only: Array[EnemyData.Layer] = [EnemyData.Layer.AIR]
	assert_null(Targeting.pick(_pool.active, Vector3.ZERO, 12.0, air_only))


func test_nothing_in_range() -> void:
	_pool.acquire(SKIFF, _lane, 0.0)
	assert_null(Targeting.pick(_pool.active, Vector3.ZERO, 12.0, _surface))


func test_can_hit_checks_range_life_and_layer() -> void:
	var enemy: Enemy = _pool.acquire(SKIFF, _lane, 40.0)
	assert_true(Targeting.can_hit(enemy, Vector3(0, 0, 5), 36.0, _surface))
	assert_false(Targeting.can_hit(enemy, Vector3(0, 0, 7), 36.0, _surface))
	_pool.damage(enemy, 1000.0)
	assert_false(Targeting.can_hit(enemy, Vector3(0, 0, 5), 36.0, _surface))
	assert_false(Targeting.can_hit(null, Vector3.ZERO, 36.0, _surface))


func test_retarget_rate() -> void:
	assert_almost_eq(1.0 / Targeting.RETARGET_INTERVAL, 5.0, 0.0001)
