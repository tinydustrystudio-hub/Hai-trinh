extends GutTest
## Xê dịch của địch (góp ý 5): mỗi địch lượn nhẹ quanh đường luồng bằng đường lượn riêng; hướng và đường đi
## vẫn theo luồng, tốc độ dọc luồng của cùng một loại địch như nhau.

const SKIFF: EnemyData = preload("res://data/enemies/raider_skiff.tres")
const RULES: CombatRules = preload("res://data/combat_rules.tres")

var _lane: Lane
var _pool: EnemyPool


func before_each() -> void:
	_lane = Lane.new()
	_lane.setup(0, PackedVector3Array([Vector3(-150, 0, 0), Vector3(150, 0, 0)]), &"LANE_EAST")
	add_child_autofree(_lane)
	_pool = add_child_autofree(EnemyPool.new())


func test_each_enemy_gets_its_own_path() -> void:
	var a: Enemy = _pool.acquire(SKIFF, _lane, 100.0)
	var b: Enemy = _pool.acquire(SKIFF, _lane, 100.0)
	assert_gt(a.wander_amplitude(), 0.0)
	assert_ne(a.wander_at(40.0), b.wander_at(40.0), "hai địch lượn khác nhau")
	assert_ne(a.wander_at(40.0), a.wander_at(60.0), "và đổi dần theo quãng đường")


func test_wander_stays_inside_amplitude_and_follows_lane() -> void:
	var enemy: Enemy = _pool.acquire(SKIFF, _lane, 0.0)
	var widest: float = 0.0
	for k: int in 200:
		enemy.distance = float(k) * 1.2
		enemy._place(0.0)
		# Lane chạy dọc trục x: lệch ngang là độ lệch theo z (lệch cố định cộng đường lượn).
		widest = maxf(widest, absf(enemy.position.z))
		assert_lte(absf(enemy.position.z), EnemyPool.LATERAL_SPREAD + RULES.wander_amplitude + 0.001)
	assert_gt(widest, 0.2, "có lượn thật")


func test_heading_tilts_toward_the_side_it_moves() -> void:
	var enemy: Enemy = _pool.acquire(SKIFF, _lane, 0.0)
	var maximum: float = 0.0
	for k: int in 200:
		var heading: Vector3 = enemy.heading_at(float(k) * 1.2)
		assert_almost_eq(heading.length(), 1.0, 0.0001)
		assert_gt(heading.x, 0.8, "vẫn đi theo luồng, không quay ngược hay ngang")
		maximum = maxf(maximum, absf(heading.z))
	assert_gt(maximum, 0.03)
	assert_lt(maximum, 0.5, "chỉ xoay nhẹ")


func test_speed_along_lane_is_the_same_for_all() -> void:
	var a: Enemy = _pool.acquire(SKIFF, _lane, 10.0)
	var b: Enemy = _pool.acquire(SKIFF, _lane, 10.0)
	var before: float = a.distance
	a.advance(2.0, 0.0)
	b.advance(2.0, 0.0)
	assert_almost_eq(a.distance - before, SKIFF.speed_units() * 2.0, 0.0001)
	assert_almost_eq(a.distance, b.distance, 0.0001, "cùng loại cùng luồng cùng tốc độ dọc luồng")


func test_clear_wander_goes_straight() -> void:
	var enemy: Enemy = _pool.acquire(SKIFF, _lane, 20.0)
	enemy.lateral_offset = 0.0
	enemy.clear_wander()
	assert_eq(enemy.wander_at(33.0), Vector2.ZERO)
	enemy._place(0.0)
	assert_almost_eq(enemy.position.z, 0.0, 0.0001)


func test_wander_is_data_driven() -> void:
	assert_gt(RULES.wander_amplitude, 0.0)
	assert_lt(RULES.wander_wavelength_min, RULES.wander_wavelength_max)
