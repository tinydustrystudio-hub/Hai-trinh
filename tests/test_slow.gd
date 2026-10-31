extends GutTest
## Làm chậm (kế hoạch mục 5.4, GDD mục 3.4): tốc độ = gốc × (1 − tổng chậm); cộng dồn giữa các lô cốt,
## trần 70% (trùm 40%); cùng một lô cốt không tự cộng dồn; hết hạn thì hết chậm. Lô Cốt Keo làm Ca Nô chậm rõ.

const GLUE: TowerData = preload("res://data/towers/glue_sprayer.tres")
const RAM: EnemyData = preload("res://data/enemies/ram_drone.tres")
const CRAB: EnemyData = preload("res://data/enemies/spiked_crab.tres")

var _status: StatusEffects


func before_each() -> void:
	_status = StatusEffects.new()


func test_speed_formula() -> void:
	assert_almost_eq(StatusEffects.speed_factor(0.3), 0.7, 0.0001)
	assert_almost_eq(StatusEffects.speed_factor(0.0), 1.0, 0.0001)


func test_sources_stack_up_to_cap() -> void:
	_status.apply_slow(1, 0.30, 2.0)
	assert_almost_eq(_status.total_slow(false), 0.30, 0.0001)
	_status.apply_slow(2, 0.25, 2.0)
	assert_almost_eq(_status.total_slow(false), 0.55, 0.0001)
	_status.apply_slow(3, 0.45, 2.0)
	assert_almost_eq(_status.total_slow(false), 0.70, 0.0001, "trần 70%")


func test_boss_cap_is_forty_percent() -> void:
	_status.apply_slow(1, 0.30, 2.0)
	_status.apply_slow(2, 0.30, 2.0)
	assert_almost_eq(_status.total_slow(true), 0.40, 0.0001)


func test_same_source_refreshes_without_stacking() -> void:
	_status.apply_slow(7, 0.30, 2.0)
	_status.apply_slow(7, 0.30, 2.0)
	_status.apply_slow(7, 0.30, 2.0)
	assert_almost_eq(_status.total_slow(false), 0.30, 0.0001)
	_status.advance(1.5)
	_status.apply_slow(7, 0.35, 2.0)
	assert_almost_eq(_status.total_slow(false), 0.35, 0.0001, "nâng cấp thì dùng mức mới")
	_status.advance(1.9)
	assert_true(_status.is_slowed(), "làm mới thời hạn")


func test_slow_expires() -> void:
	_status.apply_slow(1, 0.30, 2.0)
	_status.advance(1.99)
	assert_true(_status.is_slowed())
	_status.advance(0.02)
	assert_false(_status.is_slowed())
	assert_eq(_status.total_slow(false), 0.0)


func test_many_sources_do_not_overflow() -> void:
	for i: int in StatusEffects.MAX_SOURCES + 5:
		_status.apply_slow(i + 1, 0.1, 1.0 + float(i))
	assert_almost_eq(_status.total_slow(false), 0.70, 0.0001)


func test_glue_levels_from_gdd() -> void:
	var expected: Array[Array] = [[60, 0.30, 1.0, 2.5, 2.0], [50, 0.35, 1.1, 2.5, 2.0], [80, 0.40, 1.2, 2.7, 4.0], [110, 0.45, 1.3, 2.8, 4.0]]
	for i: int in expected.size():
		var level: TowerLevel = GLUE.level(i + 1)
		assert_eq(level.steel_cost, expected[i][0])
		assert_almost_eq(level.slow_amount, expected[i][1], 0.0001)
		assert_almost_eq(level.glue_radius_cells, expected[i][2], 0.0001)
		assert_almost_eq(level.range_cells, expected[i][3], 0.0001)
		assert_almost_eq(level.damage_per_second, expected[i][4], 0.0001)
		assert_almost_eq(level.slow_duration, 2.0, 0.0001)
		assert_almost_eq(level.fire_rate, 2.0, 0.0001, "phun mỗi 0,5 giây")
	assert_almost_eq(GLUE.mega_multiplier, 1.5, 0.0001, "lô cốt hỗ trợ: MEGA tăng hiệu ứng ×1,5")


func _glue_setup() -> Array:
	var lane: Lane = Lane.new()
	lane.setup(0, PackedVector3Array([Vector3(-40, 0, 0), Vector3(40, 0, 0)]), &"LANE_EAST")
	add_child_autofree(lane)
	var pool: EnemyPool = add_child_autofree(EnemyPool.new())
	var pad: TowerPad = add_child_autofree(load("res://battle/map/tower_pad.tscn").instantiate())
	pad.position = Vector3(0, 0, 5)
	var glue: GlueSprayer = GlueSprayer.new()
	glue.setup(GLUE, pad, pool, null)
	pad.add_child(glue)
	return [lane, pool, glue]


func test_ram_drone_slows_clearly_in_glue() -> void:
	var parts: Array = _glue_setup()
	var pool: EnemyPool = parts[1]
	var glue: GlueSprayer = parts[2]
	var ram: Enemy = pool.acquire(RAM, parts[0], 38.0)
	ram.lateral_offset = 0.0
	# Lô cốt phun vào chỗ Ca Nô, Ca Nô dính keo.
	glue.tick(0.05)
	assert_eq(glue.sprays, 1)
	assert_true(glue.in_glue(ram.global_position))
	assert_true(ram.status.is_slowed())
	var before: float = ram.distance
	pool.advance(0.5)
	var moved: float = ram.distance - before
	# Tốc độ gốc 1,5 ô/giây = 6 đơn vị/giây; chậm 30% còn 4,2.
	assert_almost_eq(moved / 0.5, RAM.speed_units() * 0.7, 0.05)


func test_glue_damage_per_second() -> void:
	var parts: Array = _glue_setup()
	var pool: EnemyPool = parts[1]
	var glue: GlueSprayer = parts[2]
	var crab: Enemy = pool.acquire(CRAB, parts[0], 40.0)
	crab.lateral_offset = 0.0
	for i: int in 20:
		glue.tick(0.05)
	# 2 sát thương/giây trong 1 giây, giáp 50%.
	assert_almost_eq(800.0 - crab.health, 1.0, 0.06)


func test_two_glue_towers_stack() -> void:
	var parts: Array = _glue_setup()
	var pool: EnemyPool = parts[1]
	var pad: TowerPad = add_child_autofree(load("res://battle/map/tower_pad.tscn").instantiate())
	pad.position = Vector3(0, 0, -5)
	var second: GlueSprayer = GlueSprayer.new()
	second.setup(GLUE, pad, pool, null)
	pad.add_child(second)
	var ram: Enemy = pool.acquire(RAM, parts[0], 40.0)
	ram.lateral_offset = 0.0
	(parts[2] as GlueSprayer).tick(0.05)
	second.tick(0.05)
	assert_almost_eq(ram.status.total_slow(false), 0.6, 0.0001)


func test_puddles_expire_after_slow_duration() -> void:
	var parts: Array = _glue_setup()
	var glue: GlueSprayer = parts[2]
	glue.spray(Vector3(3, 0, 0))
	assert_true(glue.in_glue(Vector3(3, 0, 0)))
	for i: int in 41:
		glue.tick(0.05)
	assert_false(glue.in_glue(Vector3(3, 0, 0)))
