extends GutTest
## Giãn cách địch (góp ý 4, mục 14): hai địch trên cùng luồng cách nhau ít nhất nửa kích thước thân,
## địch càng mạnh càng cách xa; địch phía sau dồn lại chứ không chồng lên địch phía trước.

const RULES: CombatRules = preload("res://data/combat_rules.tres")
const SKIFF: EnemyData = preload("res://data/enemies/raider_skiff.tres")
const RAM: EnemyData = preload("res://data/enemies/ram_drone.tres")
const CRAB: EnemyData = preload("res://data/enemies/spiked_crab.tres")
const UNIT: float = MapLayout.UNITS_PER_CELL

var _lane: Lane
var _pool: EnemyPool


func before_each() -> void:
	_lane = Lane.new()
	_lane.setup(0, PackedVector3Array([Vector3(-100, 0, 0), Vector3(100, 0, 0)]), &"LANE_EAST")
	add_child_autofree(_lane)
	_pool = add_child_autofree(EnemyPool.new())


func test_weakest_enemy_keeps_half_a_body() -> void:
	assert_almost_eq(RULES.spacing_ratio(RULES.spacing_reference_health), 0.5, 0.0001)
	assert_almost_eq(RULES.spacing_ratio(1.0), 0.5, 0.0001, "yếu hơn tham chiếu vẫn không dưới 1/2")


func test_stronger_means_farther() -> void:
	assert_gt(RULES.spacing_ratio(120.0), RULES.spacing_ratio(60.0))
	assert_almost_eq(RULES.spacing_ratio(120.0), 0.75, 0.0001, "máu gấp đôi thì thêm 0,25")
	assert_gt(RULES.spacing_ratio(CRAB.max_health), RULES.spacing_ratio(SKIFF.max_health))
	assert_gt(RULES.min_center_gap(CRAB, CRAB, UNIT), RULES.min_center_gap(SKIFF, SKIFF, UNIT))


func test_min_center_gap_is_hull_plus_gap() -> void:
	# Hai Xuồng Cướp: nửa thân + nửa thân + 1/2 thân.
	var expected: float = (SKIFF.size_cells + 0.5 * SKIFF.size_cells) * UNIT
	assert_almost_eq(RULES.min_center_gap(SKIFF, SKIFF, UNIT), expected, 0.0001)
	# Cặp hỗn hợp theo địch cần nhiều chỗ hơn.
	assert_gt(RULES.min_center_gap(SKIFF, CRAB, UNIT), RULES.min_center_gap(SKIFF, SKIFF, UNIT))


func _run_seconds(seconds: float) -> void:
	var elapsed: float = 0.0
	while elapsed < seconds:
		_pool.advance(0.1)
		elapsed += 0.1


func _assert_spacing_kept() -> void:
	var by_distance: Array[Enemy] = _pool.active.duplicate()
	by_distance.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.distance > b.distance)
	for k: int in range(1, by_distance.size()):
		var need: float = RULES.min_center_gap(by_distance[k - 1].data, by_distance[k].data, UNIT)
		assert_gte(by_distance[k - 1].distance - by_distance[k].distance, need - 0.001, "địch %d đi sát địch trước" % k)


func test_followers_queue_behind_a_slow_leader() -> void:
	# Cua Giáp Gai (chậm) đi trước, Ca Nô Cảm Tử (nhanh) đuổi theo từ phía sau.
	_pool.acquire(CRAB, _lane, 30.0)
	_pool.acquire(RAM, _lane, 0.0)
	_pool.acquire(RAM, _lane, 0.0)
	_run_seconds(20.0)
	_assert_spacing_kept()
	var crab: Enemy = _pool.active[0]
	var ram: Enemy = _pool.active[1]
	assert_lt(ram.distance, crab.distance, "Ca Nô không vượt Cua")
	assert_almost_eq(crab.distance - ram.distance, RULES.min_center_gap(CRAB, RAM, UNIT), 0.2, "Ca Nô dồn sát tới mức tối thiểu rồi dừng")


func test_stacked_spawns_spread_out() -> void:
	for i: int in 6:
		_pool.acquire(SKIFF, _lane, 0.0)
	_run_seconds(15.0)
	_assert_spacing_kept()
	var distances: Array[float] = []
	for enemy: Enemy in _pool.active:
		distances.append(enemy.distance)
	assert_gt(distances.max() - distances.min(), 5.0 * RULES.min_center_gap(SKIFF, SKIFF, UNIT) - 0.1)


func test_leader_never_slowed_by_followers() -> void:
	var leader: Enemy = _pool.acquire(SKIFF, _lane, 40.0)
	_pool.acquire(SKIFF, _lane, 38.0)
	var before: float = leader.distance
	_run_seconds(2.0)
	assert_almost_eq(leader.distance - before, SKIFF.speed_units() * 2.0, 0.01)


func test_other_lanes_do_not_block() -> void:
	var other: Lane = Lane.new()
	other.setup(1, PackedVector3Array([Vector3(-100, 0, 5), Vector3(100, 0, 5)]), &"LANE_WEST")
	add_child_autofree(other)
	var a: Enemy = _pool.acquire(CRAB, _lane, 20.0)
	var b: Enemy = _pool.acquire(RAM, other, 19.0)
	_run_seconds(1.0)
	assert_gt(b.distance, 19.0 + RAM.speed_units() * 0.9, "luồng khác không cản nhau")
	assert_not_null(a)
