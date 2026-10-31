extends GutTest
## Lô Cốt Tia Sáng (góp ý 4, mục 9): chùm sáng liên tục, sát thương mỗi giây tăng dần khi giữ trên một mục tiêu,
## bỏ qua một phần giáp, đổi mục tiêu thì hội tụ lại; nạp Quá tải theo thời gian chiếu; MEGA ×3.

const BATTLE_SCENE: PackedScene = preload("res://battle/battle.tscn")
const BEAM: TowerData = preload("res://data/towers/light_beam.tres")
const SKIFF: EnemyData = preload("res://data/enemies/raider_skiff.tres")
const CRAB: EnemyData = preload("res://data/enemies/spiked_crab.tres")
const STEP: float = 0.25

var _battle: BattleController
var _lane: Lane


func before_each() -> void:
	_battle = add_child_autofree(BATTLE_SCENE.instantiate())
	_battle.economy.reset(5000)
	_lane = _battle.lanes[0]


func _place(pad_index: int = 4) -> LightBeam:
	return _battle.build_tower(_battle.island.pads[pad_index], BEAM) as LightBeam


func _enemy_near(tower: Tower, data: EnemyData) -> Enemy:
	# Đặt địch trong tầm: tìm điểm trên luồng gần tháp nhất.
	var best: float = INF
	var at: float = 0.0
	for k: int in 200:
		var d: float = _lane.length() * float(k) / 199.0
		var dist: float = Vector2(_lane.position_at(d).x - tower.global_position.x, _lane.position_at(d).z - tower.global_position.z).length()
		if dist < best:
			best = dist
			at = d
	var enemy: Enemy = _battle.enemy_pool.acquire(data, _lane, at)
	enemy.lateral_offset = 0.0
	enemy._place(0.0)
	return enemy


func test_data_levels() -> void:
	assert_eq(BEAM.max_level(), 4)
	assert_eq(BEAM.level(1).steel_cost, 90)
	assert_gt(BEAM.level(4).damage_per_second, BEAM.level(1).damage_per_second)
	assert_gt(BEAM.level(4).range_cells, BEAM.level(1).range_cells)
	assert_true(BEAM.can_target(EnemyData.Layer.SURFACE))
	assert_true(BattleController.TOWER_SCRIPTS.has(&"light_beam"))
	assert_true(_battle.tower_choices.has(BEAM))


func test_damage_ramps_with_focus() -> void:
	var level: TowerLevel = BEAM.level(1)
	assert_almost_eq(LightBeam.damage_for(level, 0.0), level.damage_per_second, 0.0001)
	assert_almost_eq(LightBeam.damage_for(level, level.beam_ramp_seconds * 0.5), level.damage_per_second * (1.0 + level.beam_ramp_bonus * 0.5), 0.0001)
	assert_almost_eq(LightBeam.damage_for(level, 99.0), level.damage_per_second * (1.0 + level.beam_ramp_bonus), 0.0001, "có trần")


func test_beam_hits_continuously_and_draws() -> void:
	var tower: LightBeam = _place()
	assert_not_null(tower)
	var enemy: Enemy = _enemy_near(tower, CRAB)
	var before: float = enemy.health
	for i: int in 4:
		tower.tick(STEP)
	assert_lt(enemy.health, before)
	assert_true(tower.is_beaming())
	assert_gt(tower.focus_time, 0.9)
	_battle.beams.begin()
	tower.draw_beam(_battle.beams)
	_battle.beams.finish()
	assert_eq(_battle.beams.count(), 1)


func test_total_damage_matches_ramp() -> void:
	var tower: LightBeam = _place()
	var tough: EnemyData = CRAB.duplicate()
	tough.max_health = 100000.0
	tough.armor = 0.0
	var enemy: Enemy = _enemy_near(tower, tough)
	enemy.status.clear()
	var level: TowerLevel = tower.stats()
	for i: int in 16:
		tower.tick(STEP)
	# Sát thương sau giáp 0 rồi nhân (1 − 0) = đúng công thức, tích phân bậc thang theo từng nhịp.
	var expected: float = 0.0
	var focus: float = 0.0
	for i: int in 16:
		expected += LightBeam.damage_for(level, focus) * STEP
		focus += STEP
	assert_almost_eq(tower.damage_dealt, expected, 0.01)


func test_armor_piercing_beam_hurts_armored_more_than_plain_math() -> void:
	var tower: LightBeam = _place()
	var enemy: Enemy = _enemy_near(tower, CRAB)
	tower.tick(STEP)
	var level: TowerLevel = tower.stats()
	var raw: float = level.damage_per_second * STEP
	var armor: float = enemy.data.armor
	var plain: float = Enemy.damage_after_armor(raw, armor)
	var piercing: float = Enemy.damage_after_armor(raw, armor * (1.0 - level.beam_armor_ignore))
	assert_almost_eq(tower.damage_dealt, piercing, 0.001)
	assert_gt(piercing, plain)


func test_switching_target_resets_focus() -> void:
	var tower: LightBeam = _place()
	var first: Enemy = _enemy_near(tower, CRAB)
	for i: int in 8:
		tower.tick(STEP)
	assert_gt(tower.focus_time, 1.5)
	_battle.enemy_pool.release(first)
	tower.target = null
	var second: Enemy = _enemy_near(tower, CRAB)
	tower.tick(STEP)
	assert_lt(tower.focus_time, 0.6, "mục tiêu mới thì hội tụ lại")
	assert_not_null(second)


func test_idle_without_target() -> void:
	var tower: LightBeam = _place()
	tower.tick(STEP)
	assert_false(tower.is_beaming())
	assert_eq(tower.focus_time, 0.0)
	assert_eq(tower.overload.charge, 0.0)


func test_overload_fills_after_fourteen_seconds_of_beam() -> void:
	var tower: LightBeam = _place()
	var tough: EnemyData = CRAB.duplicate()
	tough.max_health = 1000000.0
	_enemy_near(tower, tough)
	var t: float = 0.0
	while not tower.overload.is_ready() and t < 40.0:
		tower.tick(STEP)
		t += STEP
	assert_almost_eq(t, BEAM.overload_charge_seconds, 0.6)


func test_mega_triples_beam_damage() -> void:
	var tower: LightBeam = _place()
	var tough: EnemyData = CRAB.duplicate()
	tough.max_health = 1000000.0
	tough.armor = 0.0
	_enemy_near(tower, tough)
	tower.overload.add_charge(1.0)
	var calm: LightBeam = _place(5)
	_enemy_near(calm, tough)
	assert_true(tower.activate_mega())
	for i: int in 4:
		tower.tick(STEP)
		calm.tick(STEP)
	assert_almost_eq(tower.damage_dealt / calm.damage_dealt, BEAM.mega_multiplier, 0.3)


func test_beam_emits_fire_events_for_sound() -> void:
	watch_signals(Events)
	var tower: LightBeam = _place()
	_enemy_near(tower, CRAB)
	for i: int in 8:
		tower.tick(STEP)
	assert_signal_emit_count(Events, "tower_fired", 8 / 1)  # mỗi nhịp 0,25 giây là một lần báo
