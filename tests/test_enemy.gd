extends GutTest
## Địch: sát thương sau giáp, đi theo luồng đúng tốc độ, lọt khi tới cuối luồng.

const SKIFF: EnemyData = preload("res://data/enemies/raider_skiff.tres")
const CRAB: EnemyData = preload("res://data/enemies/spiked_crab.tres")

var _lane: Lane
var _enemy: Enemy


func before_each() -> void:
	_lane = Lane.new()
	_lane.setup(0, PackedVector3Array([Vector3(0, 0, -20), Vector3(0, 0, 0)]), &"LANE_NORTH")
	add_child_autofree(_lane)
	_enemy = add_child_autofree(Enemy.new())
	_enemy.spawn(SKIFF, _lane, 0.0, 0.0)


func test_damage_after_armor() -> void:
	assert_almost_eq(Enemy.damage_after_armor(6.0, 0.1), 5.4, 0.0001)
	assert_almost_eq(Enemy.damage_after_armor(60.0, 0.5), 30.0, 0.0001)
	assert_eq(Enemy.damage_after_armor(-5.0, 0.1), 0.0)


func test_take_damage_uses_armor_and_stops_at_zero() -> void:
	assert_almost_eq(_enemy.take_damage(10.0), 9.0, 0.0001)
	assert_almost_eq(_enemy.health, 51.0, 0.0001)
	assert_almost_eq(_enemy.take_damage(1000.0), 51.0, 0.0001)
	assert_true(_enemy.is_dead())
	assert_eq(_enemy.health_ratio(), 0.0)


func test_crab_needs_many_hits() -> void:
	_enemy.spawn(CRAB, _lane, 0.0, 0.0)
	# Súng Máy cấp 1: 6 sát thương mỗi phát; giáp 50% → 3; 800 máu cần 267 phát.
	var hits: int = 0
	while not _enemy.is_dead():
		_enemy.take_damage(6.0)
		hits += 1
	assert_eq(hits, 267)


func test_moves_at_data_speed() -> void:
	assert_false(_enemy.advance(1.0, 0.0))
	assert_almost_eq(_enemy.distance, 3.2, 0.0001)
	assert_almost_eq(_enemy.position.z, -16.8, 0.05)


func test_speed_multiplier_slows() -> void:
	_enemy.speed_multiplier = 0.5
	_enemy.advance(1.0, 0.0)
	assert_almost_eq(_enemy.distance, 1.6, 0.0001)


func test_leaks_at_end_of_lane() -> void:
	# 20 đơn vị ở 3,2 đơn vị/giây: lọt sau 6,25 giây.
	assert_false(_enemy.advance(6.2, 0.0))
	assert_true(_enemy.advance(0.1, 0.0))


func test_follows_wave_height() -> void:
	_enemy.advance(0.5, 0.3)
	assert_almost_eq(_enemy.position.y, 0.3, 0.0001)


func test_faces_along_lane() -> void:
	_enemy.advance(1.0, 0.0)
	assert_almost_eq(-_enemy.basis.z.normalized().z, 1.0, 0.01)
