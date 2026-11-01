extends GutTest
## Sát thương Súng Máy (GDD mục 3.3) qua giáp (kế hoạch mục 5.4) và nhịp bắn.

const MG: TowerData = preload("res://data/towers/machine_gun.tres")
const SKIFF: EnemyData = preload("res://data/enemies/raider_skiff.tres")
const CRAB: EnemyData = preload("res://data/enemies/spiked_crab.tres")

var _pool: EnemyPool
var _lane: Lane
var _pad: TowerPad
var _gun: MachineGun


func before_each() -> void:
	_lane = Lane.new()
	_lane.setup(0, PackedVector3Array([Vector3(-40, 0, 0), Vector3(40, 0, 0)]), &"LANE_EAST")
	add_child_autofree(_lane)
	_pool = add_child_autofree(EnemyPool.new())
	_pad = add_child_autofree(load("res://battle/map/tower_pad.tscn").instantiate())
	_pad.position = Vector3(0, 0, 6)
	_gun = MachineGun.new()
	_gun.setup(MG, _pad, _pool, null)
	_pad.add_child(_gun)


func test_machine_gun_levels_from_gdd() -> void:
	var expected: Array[Array] = [[70, 6.0, 5.0, 3.0], [60, 9.0, 5.0, 3.2], [90, 12.0, 6.0, 3.4], [130, 16.0, 6.0, 3.6]]
	assert_eq(MG.max_level(), 4, "cấp 5 là hai nhánh, làm ở bước 9")
	for i: int in expected.size():
		var level: TowerLevel = MG.level(i + 1)
		assert_eq(level.steel_cost, expected[i][0])
		assert_eq(level.damage, expected[i][1])
		assert_eq(level.fire_rate, expected[i][2])
		# Người duyệt (1/11): tầm bắn mọi lô cốt tăng 25% so với số trong GDD.
		assert_almost_eq(level.range_cells, expected[i][3] * TowerData.RANGE_BONUS, 0.0001)
	assert_true(MG.can_target(EnemyData.Layer.SURFACE))
	assert_false(MG.can_target(EnemyData.Layer.AIR))


func test_one_shot_after_armor() -> void:
	var enemy: Enemy = _pool.acquire(SKIFF, _lane, 40.0)
	_gun.shoot(enemy)
	# 6 × (1 − 10%) = 5,4.
	assert_almost_eq(enemy.health, 60.0 - 5.4, 0.0001)


func test_kills_raider_skiff_with_twelve_shots() -> void:
	var enemy: Enemy = _pool.acquire(SKIFF, _lane, 40.0)
	watch_signals(Events)
	for i: int in 11:
		_gun.shoot(enemy)
	assert_true(enemy.active)
	_gun.shoot(enemy)
	assert_false(enemy.active)
	assert_signal_emitted_with_parameters(Events, "enemy_killed", [enemy, 5])


func test_armor_halves_damage_on_crab() -> void:
	var enemy: Enemy = _pool.acquire(CRAB, _lane, 40.0)
	_gun.shoot(enemy)
	assert_almost_eq(enemy.health, 800.0 - 3.0, 0.0001)


func test_fires_at_fire_rate() -> void:
	_pool.acquire(CRAB, _lane, 40.0)
	# Phát đầu ngay khi thấy mục tiêu, rồi cứ 0,2 giây một phát: 10 nhịp 0,1 giây là 5 phát.
	for i: int in 10:
		_gun.tick(0.1)
	assert_between(_gun.shots_fired, 5, 6)
	var before: int = _gun.shots_fired
	_gun.tick(1.0)
	assert_eq(_gun.shots_fired - before, 5, "nhịp dài vẫn đúng tốc bắn")


func test_does_not_fire_without_target_or_out_of_range() -> void:
	_pool.acquire(SKIFF, _lane, 0.0)
	_gun.tick(1.0)
	assert_eq(_gun.shots_fired, 0, "địch ở x = −40, ngoài tầm 12")
	assert_null(_gun.target)


func test_no_burst_after_idle() -> void:
	_gun.tick(5.0)
	_pool.acquire(CRAB, _lane, 40.0)
	_gun.tick(0.01)
	assert_eq(_gun.shots_fired, 1, "không dồn phát trong lúc không có mục tiêu")


func test_kills_skiff_in_about_two_and_a_half_seconds() -> void:
	var enemy: Enemy = _pool.acquire(SKIFF, _lane, 40.0)
	var elapsed: float = 0.0
	while enemy.active and elapsed < 10.0:
		_gun.tick(0.05)
		elapsed += 0.05
	assert_false(enemy.active)
	# 12 phát, phát đầu ở t = 0: phát thứ 12 ở t = 2,2 giây.
	assert_almost_eq(elapsed, 2.2, 0.06)
