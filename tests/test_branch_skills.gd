extends GutTest
## Bốn kỹ năng nhánh cấp 5 (GDD Phần 3): Mưa Đạn – Quét Ngang, Xuyên Giáp – Đạn Lõi Thép,
## Hồ Keo – Dính Chặt, Keo Ăn Mòn – Bóc Giáp.

const MG: TowerData = preload("res://data/towers/machine_gun.tres")
const GLUE: TowerData = preload("res://data/towers/glue_sprayer.tres")
const SKIFF: EnemyData = preload("res://data/enemies/raider_skiff.tres")
const RAM: EnemyData = preload("res://data/enemies/ram_drone.tres")
const CRAB: EnemyData = preload("res://data/enemies/spiked_crab.tres")

var _pool: EnemyPool
var _lane: Lane
var _lanes: Array[Lane] = []


func before_each() -> void:
	_lane = Lane.new()
	_lane.setup(0, PackedVector3Array([Vector3(-40, 0, 0), Vector3(40, 0, 0)]), &"LANE_EAST")
	add_child_autofree(_lane)
	_lanes = [_lane]
	_pool = add_child_autofree(EnemyPool.new())


func _tower(script: GDScript, data: TowerData, branch_index: int, at: Vector3) -> Tower:
	var pad: TowerPad = add_child_autofree(load("res://battle/map/tower_pad.tscn").instantiate())
	pad.position = at
	var tower: Tower = script.new()
	tower.setup(data, pad, _pool, null)
	pad.add_child(tower)
	for i: int in data.max_level() - 1:
		tower.level_up()
	tower.choose_branch(data.branches[branch_index], _lanes)
	return tower


func _enemy(data: EnemyData, distance: float) -> Enemy:
	var enemy: Enemy = _pool.acquire(data, _lane, distance)
	enemy.lateral_offset = 0.0
	enemy._place(0.0)
	return enemy


# --- Mưa Đạn – Quét Ngang ---

func test_bullet_rain_hits_three_targets_per_volley() -> void:
	var gun: MachineGun = _tower(MachineGun, MG, 0, Vector3(0, 0, 6))
	var crabs: Array[Enemy] = [_enemy(CRAB, 36.0), _enemy(CRAB, 40.0), _enemy(CRAB, 44.0), _enemy(CRAB, 46.0)]
	gun.tick(0.01)
	assert_eq(gun.shots_fired, 3, "một loạt bắn 3 mục tiêu")
	var hit: int = 0
	for crab: Enemy in crabs:
		if crab.health < CRAB.max_health:
			hit += 1
	assert_eq(hit, 3)


func test_sweep_every_six_seconds_hits_all_in_front() -> void:
	# Lô cốt lùi ra sau để cả 5 con nằm trong hình quạt 90°.
	var gun: MachineGun = _tower(MachineGun, MG, 0, Vector3(0, 0, 10))
	var front: Array[Enemy] = [_enemy(CRAB, 38.0), _enemy(CRAB, 40.0), _enemy(CRAB, 42.0), _enemy(CRAB, 43.0), _enemy(CRAB, 44.0)]
	# Một con phía sau lô cốt (z dương xa hơn) ngoài hình quạt.
	var behind_lane: Lane = Lane.new()
	behind_lane.setup(1, PackedVector3Array([Vector3(-40, 0, 14), Vector3(40, 0, 14)]), &"LANE_SOUTH")
	add_child_autofree(behind_lane)
	var behind: Enemy = _pool.acquire(CRAB, behind_lane, 40.0)
	behind.lateral_offset = 0.0
	behind._place(0.0)
	var before: float = behind.health
	# Bước 0,25 giây cộng không sai số dấu phẩy động.
	for i: int in 23:
		gun.tick(0.25)
	assert_eq(gun.sweeps, 0, "chưa đủ 6 giây")
	gun.tick(0.25)
	assert_eq(gun.sweeps, 1)
	assert_eq(behind.health, before, "địch phía sau không trúng quét")
	for enemy: Enemy in front:
		assert_lt(enemy.health, CRAB.max_health)
	assert_eq(gun.sweep(), 5, "quét trúng cả 5 con phía trước")


# --- Xuyên Giáp – Đạn Lõi Thép ---

func test_armor_piercer_ignores_seventy_percent_armor() -> void:
	var gun: MachineGun = _tower(MachineGun, MG, 1, Vector3(0, 0, 6))
	var crab: Enemy = _enemy(CRAB, 40.0)
	gun.shoot(crab)
	# Giáp 50% còn 15%: 60 × 0,85 = 51.
	assert_almost_eq(CRAB.max_health - crab.health, 51.0, 0.001)


func test_core_round_every_fourth_shot_on_heavy_armor() -> void:
	var gun: MachineGun = _tower(MachineGun, MG, 1, Vector3(0, 0, 6))
	var crab: Enemy = _enemy(CRAB, 40.0)
	var damage: Array[float] = []
	for i: int in 4:
		var before: float = crab.health
		gun.shoot(crab)
		damage.append(before - crab.health)
	assert_almost_eq(damage[0], 51.0, 0.001)
	assert_almost_eq(damage[2], 51.0, 0.001)
	assert_almost_eq(damage[3], 153.0, 0.001, "phát thứ 4 ×3")


func test_core_round_ignores_light_armor() -> void:
	var gun: MachineGun = _tower(MachineGun, MG, 1, Vector3(0, 0, 6))
	assert_false(gun.is_core_round(4, _enemy(SKIFF, 40.0)), "giáp 10% là bậc 1, dưới bậc 3")
	assert_true(gun.is_core_round(4, _enemy(CRAB, 30.0)))
	assert_false(gun.is_core_round(3, _enemy(CRAB, 31.0)))


# --- Hồ Keo – Dính Chặt ---

func test_glue_lake_is_fixed_on_the_lane() -> void:
	var glue: GlueSprayer = _tower(GlueSprayer, GLUE, 0, Vector3(0, 0, 6))
	assert_true(glue.has_lake())
	assert_almost_eq(glue.lake_center, Vector3(0, 0, 0), Vector3.ONE * 0.05, "điểm luồng gần lô cốt nhất")
	var ram: Enemy = _enemy(RAM, 40.0)
	glue.tick(0.05)
	assert_eq(glue.sprays, 0, "hồ keo không phun")
	assert_almost_eq(ram.status.total_slow(false), 0.55, 0.0001)
	# Hồ không cạn sau nhiều giây.
	for i: int in 100:
		glue.tick(0.1)
	assert_true(glue.in_glue(Vector3(0, 0, 0)))


func test_sticky_holds_every_ten_seconds_for_one_and_a_half() -> void:
	var glue: GlueSprayer = _tower(GlueSprayer, GLUE, 0, Vector3(0, 0, 6))
	var crab: Enemy = _enemy(CRAB, 40.0)
	for i: int in 39:
		glue.tick(0.25)
	assert_eq(glue.holds, 0)
	glue.tick(0.25)
	assert_eq(glue.holds, 1)
	assert_true(crab.status.is_held())
	var before: float = crab.distance
	_pool.advance(1.4)
	assert_almost_eq(crab.distance, before, 0.0001, "đứng yên")
	_pool.advance(0.2)
	assert_false(crab.status.is_held(), "hết 1,5 giây")


func test_sticky_only_slows_bosses_more() -> void:
	var glue: GlueSprayer = _tower(GlueSprayer, GLUE, 0, Vector3(0, 0, 6))
	var boss_data: EnemyData = CRAB.duplicate()
	boss_data.is_boss = true
	var boss: Enemy = _enemy(boss_data, 40.0)
	glue.tick(0.05)
	assert_almost_eq(boss.status.total_slow(true), 0.4, 0.0001, "trùm chạm trần 40%")
	glue.hold_lake()
	assert_false(boss.status.is_held())
	var elite_data: EnemyData = SKIFF.duplicate()
	elite_data.is_elite = true
	var elite: Enemy = _enemy(elite_data, 41.0)
	glue.hold_lake()
	assert_false(elite.status.is_held())
	# Tàu tinh nhuệ: 55% của hồ + 20% thêm, chạm trần 70%.
	glue.tick(0.05)
	assert_almost_eq(elite.status.total_slow(false), 0.7, 0.0001)


# --- Keo Ăn Mòn – Bóc Giáp ---

func test_corrosive_glue_lowers_armor_two_tiers_for_four_seconds() -> void:
	var glue: GlueSprayer = _tower(GlueSprayer, GLUE, 1, Vector3(0, 0, 6))
	var crab: Enemy = _enemy(CRAB, 40.0)
	glue.spray(crab.global_position)
	# Bậc 4 (50%) xuống bậc 2 (20%).
	assert_almost_eq(crab.current_armor(), 0.2, 0.0001)
	crab.status.advance(3.9)
	assert_almost_eq(crab.current_armor(), 0.2, 0.0001)
	crab.status.advance(0.2)
	assert_almost_eq(crab.current_armor(), 0.5, 0.0001)


func test_armor_strip_after_three_consecutive_sprays() -> void:
	var glue: GlueSprayer = _tower(GlueSprayer, GLUE, 1, Vector3(0, 0, 6))
	var crab: Enemy = _enemy(CRAB, 40.0)
	glue.spray(crab.global_position)
	glue.spray(crab.global_position)
	assert_false(crab.status.is_armor_broken())
	glue.spray(crab.global_position)
	assert_true(crab.status.is_armor_broken())
	assert_eq(crab.current_armor(), 0.0)
	crab.status.advance(3.1)
	assert_false(crab.status.is_armor_broken())


func test_missed_spray_breaks_the_streak() -> void:
	var glue: GlueSprayer = _tower(GlueSprayer, GLUE, 1, Vector3(0, 0, 6))
	var crab: Enemy = _enemy(CRAB, 40.0)
	glue.spray(crab.global_position)
	glue.spray(crab.global_position)
	glue.spray(Vector3(-30, 0, 0))
	glue.spray(crab.global_position)
	assert_false(crab.status.is_armor_broken(), "lần phun thứ 3 trượt nên đếm lại")


func test_corrosive_glue_deals_ten_per_second() -> void:
	var glue: GlueSprayer = _tower(GlueSprayer, GLUE, 1, Vector3(0, 0, 6))
	var skiff: Enemy = _enemy(SKIFF, 40.0)
	glue.tick(0.01)
	# Đứng yên trong vùng keo 1 giây (giữ địch bằng cách không cho đi).
	var before: float = skiff.health
	for i: int in 10:
		glue.tick(0.1)
	# 10 sát thương/giây; giáp 10% bị giảm 2 bậc còn 0%.
	assert_almost_eq(before - skiff.health, 10.0, 0.6)
