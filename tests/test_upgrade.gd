extends GutTest
## Nâng cấp 1–4 theo dữ liệu, chọn nhánh 5A/5B (trận chậm 30% lúc chọn), bán hoàn 70% ngay giữa đợt;
## chỉ số đổi đúng theo Phần 3 của GDD.

const BATTLE_SCENE: PackedScene = preload("res://battle/battle.tscn")
const MG: TowerData = preload("res://data/towers/machine_gun.tres")
const GLUE: TowerData = preload("res://data/towers/glue_sprayer.tres")

var _battle: BattleController


func before_each() -> void:
	TranslationServer.set_locale("vi")
	_battle = add_child_autofree(BATTLE_SCENE.instantiate())
	_battle.economy.reset(2000)


func after_each() -> void:
	Engine.time_scale = 1.0


func test_branch_data_from_gdd() -> void:
	assert_eq(MG.branches.size(), 2)
	var rain: TowerBranch = MG.branches[0]
	var piercer: TowerBranch = MG.branches[1]
	assert_eq([rain.steel_cost, rain.damage, rain.fire_rate, rain.range_cells, rain.targets_per_shot], [200, 14.0, 8.0, 3.6 * TowerData.RANGE_BONUS, 3])
	assert_almost_eq(rain.sweep_interval, 6.0, 0.0001)
	assert_eq([piercer.steel_cost, piercer.damage, piercer.fire_rate, piercer.range_cells], [200, 60.0, 2.5, 4.2 * TowerData.RANGE_BONUS])
	assert_almost_eq(piercer.armor_ignore, 0.7, 0.0001)
	assert_eq([piercer.core_round_every, piercer.core_round_multiplier, piercer.core_round_min_armor_tier], [4, 3.0, 3])
	var lake: TowerBranch = GLUE.branches[0]
	var corrosive: TowerBranch = GLUE.branches[1]
	assert_eq([lake.steel_cost, lake.glue_radius_cells, lake.range_cells], [180, 1.8, 2.8 * TowerData.RANGE_BONUS])
	assert_almost_eq(lake.slow_amount, 0.55, 0.0001)
	assert_true(lake.fixed_lake)
	assert_eq([lake.hold_interval, lake.hold_duration], [10.0, 1.5])
	assert_almost_eq(lake.hold_resistant_slow, 0.2, 0.0001)
	assert_eq([corrosive.steel_cost, corrosive.glue_radius_cells, corrosive.range_cells, corrosive.damage_per_second], [180, 1.3, 3.0 * TowerData.RANGE_BONUS, 10.0])
	assert_almost_eq(corrosive.slow_amount, 0.4, 0.0001)
	assert_eq([corrosive.armor_tier_reduction, corrosive.armor_reduction_duration], [2, 4.0])
	assert_eq([corrosive.armor_break_hits, corrosive.armor_break_duration], [3, 3.0])


func test_upgrade_through_levels_one_to_four() -> void:
	var tower: Tower = _battle.build_tower(_battle.island.pads[0], MG)
	var expected_damage: Array[float] = [6.0, 9.0, 12.0, 16.0]
	var costs: Array[int] = [70, 60, 90, 130]
	var spent: int = 70
	assert_eq(tower.stats().damage, expected_damage[0])
	for i: int in range(1, 4):
		assert_eq(tower.next_level_cost(), costs[i])
		assert_true(_battle.upgrade_tower(tower))
		spent += costs[i]
		assert_eq(tower.level, i + 1)
		assert_eq(tower.stats().damage, expected_damage[i])
		assert_eq(_battle.economy.steel, 2000 - spent)
	assert_eq(tower.invested, 350)
	assert_false(tower.can_level_up())
	assert_true(tower.needs_branch())
	assert_false(_battle.upgrade_tower(tower), "cấp 5 phải chọn nhánh")


func test_choose_branch_sets_level_five_stats() -> void:
	var tower: Tower = _battle.build_tower(_battle.island.pads[0], MG)
	for i: int in 3:
		_battle.upgrade_tower(tower)
	var steel: int = _battle.economy.steel
	assert_true(_battle.choose_branch(tower, MG.branches[1]))
	assert_eq(tower.level, 5)
	assert_eq(tower.branch, MG.branches[1])
	assert_eq(tower.stats().damage, 60.0)
	assert_almost_eq(tower.range_units(), 4.2 * TowerData.RANGE_BONUS * MapLayout.UNITS_PER_CELL, 0.0001)
	assert_eq(_battle.economy.steel, steel - 200)
	assert_eq(tower.invested, 550)
	assert_true(tower.is_max_level())
	assert_false(_battle.choose_branch(tower, MG.branches[0]), "chỉ chọn nhánh một lần")


func test_cannot_upgrade_without_steel() -> void:
	var tower: Tower = _battle.build_tower(_battle.island.pads[0], GLUE)
	_battle.economy.reset(49)
	assert_false(_battle.upgrade_tower(tower))
	assert_eq(tower.level, 1)
	assert_eq(_battle.economy.steel, 49)


func test_sell_refunds_seventy_percent_mid_wave() -> void:
	var pad: TowerPad = _battle.island.pads[0]
	var tower: Tower = _battle.build_tower(pad, MG)
	_battle.upgrade_tower(tower)
	_battle.upgrade_tower(tower)
	# Đang giữa đợt 1.
	for i: int in 150:
		_battle.step(0.1)
	assert_eq(_battle.state, BattleController.State.FIGHTING)
	var steel: int = _battle.economy.steel
	assert_eq(_battle.sell_tower(tower), 154, "70% của 70 + 60 + 90 = 220")
	assert_eq(_battle.economy.steel, steel + 154)
	assert_false(pad.occupied)
	assert_false(_battle.towers.has(tower))
	assert_not_null(_battle.build_tower(pad, GLUE), "bệ trống lại, xây được")


func test_upgrade_ring_shows_cost_refund_and_branch() -> void:
	var tower: Tower = _battle.build_tower(_battle.island.pads[0], MG)
	var ring: UpgradeRing = _battle.hud.upgrade_ring
	ring.open(Vector2(900, 500), tower, _battle.economy.steel, _battle.economy.refund_for(tower.invested))
	assert_string_contains(ring.upgrade_button().text, "60")
	assert_string_contains(ring.sell_button().text, "+49")
	ring.set_steel(10)
	assert_true(ring.upgrade_button().disabled)
	for i: int in 3:
		_battle.upgrade_tower(tower)
	ring.open(Vector2(900, 500), tower, 1000, 0)
	assert_string_contains(ring.upgrade_button().text, tr(&"UPGRADE_BRANCH"))
	watch_signals(ring)
	ring.upgrade_button().pressed.emit()
	assert_signal_emitted(ring, "branch_requested")


func test_branch_choice_slows_battle_to_thirty_percent() -> void:
	var tower: Tower = _battle.build_tower(_battle.island.pads[0], GLUE)
	for i: int in 3:
		_battle.upgrade_tower(tower)
	_battle.open_branch_cards(tower)
	assert_true(_battle.hud.branch_cards.is_open())
	assert_eq(_battle.hud.branch_cards.cards().size(), 2)
	assert_string_contains(_battle.hud.branch_cards.cards()[0].text, "5A")
	assert_string_contains(_battle.hud.branch_cards.cards()[0].text, "Hồ Keo")
	assert_string_contains(_battle.hud.branch_cards.cards()[1].text, "Keo Ăn Mòn")
	assert_almost_eq(Engine.time_scale, 0.3, 0.0001)
	_battle.toggle_fast()
	assert_almost_eq(Engine.time_scale, 0.6, 0.0001, "×2 vẫn chậm 30% khi chọn")
	_battle.hud.branch_cards.cards()[1].pressed.emit()
	assert_eq(tower.branch, GLUE.branches[1])
	assert_false(_battle.hud.branch_cards.is_open())
	assert_almost_eq(Engine.time_scale, 2.0, 0.0001)


func test_cancel_branch_choice_restores_speed() -> void:
	var tower: Tower = _battle.build_tower(_battle.island.pads[0], MG)
	for i: int in 3:
		_battle.upgrade_tower(tower)
	_battle.open_branch_cards(tower)
	_battle.close_branch_cards()
	assert_almost_eq(Engine.time_scale, 1.0, 0.0001)
	assert_null(tower.branch)


func test_cards_big_and_side_by_side() -> void:
	assert_gte(BranchCards.CARD_SIZE.y, 120.0)
	assert_lte(BranchCards.CARD_SIZE.x * 2.0 + BranchCards.GAP, 1920.0)


func test_upgrade_ring_buttons_do_not_overlap() -> void:
	var tower: Tower = _battle.build_tower(_battle.island.pads[0], MG)
	for i: int in 3:
		_battle.upgrade_tower(tower)
	_battle.choose_branch(tower, MG.branches[0])
	var ring: UpgradeRing = _battle.hud.upgrade_ring
	ring.open(Vector2(900, 500), tower, 0, _battle.economy.refund_for(tower.invested))
	await wait_process_frames(2)
	assert_eq(ring.upgrade_button().text, tr(&"UPGRADE_MAX"))
	assert_true(ring.upgrade_button().disabled)
	var a: Rect2 = ring.upgrade_button().get_global_rect()
	var b: Rect2 = ring.sell_button().get_global_rect()
	assert_false(a.grow(4.0).intersects(b.grow(4.0)), "hai nút cách nhau ít nhất 8 px: %s và %s" % [a, b])
	assert_gte(a.size.x, 120.0)
	assert_gte(b.size.y, 120.0)
