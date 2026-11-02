extends GutTest
## Hồ sơ người chơi: ví Tiền Vàng chung, nâng cấp công trình, thanh toán sau trận, lưu và nạp.

const TEMP_PATH: String = "user://test_profile.cfg"


func before_each() -> void:
	Profile.reset_to_new()


func after_all() -> void:
	Profile.reset_to_new()
	DirAccess.remove_absolute(TEMP_PATH)


func test_new_player_starts_at_level_one() -> void:
	assert_eq(Profile.gold, Profile.NEW_PLAYER_GOLD)
	for data: BuildingData in Profile.buildings():
		assert_eq(Profile.level_of(data.id), 1)
	assert_eq(Profile.buildings().size(), 6)


func test_upgrade_spends_gold_and_raises_level() -> void:
	var cost: int = Profile.upgrade_cost(&"wave_shield")
	assert_eq(cost, 200, "cấp 2, hệ số 1,0")
	assert_true(Profile.upgrade(&"wave_shield"))
	assert_eq(Profile.level_of(&"wave_shield"), 2)
	assert_eq(Profile.gold, Profile.NEW_PLAYER_GOLD - cost)


func test_cannot_upgrade_without_gold() -> void:
	Profile.set_gold(100)
	assert_false(Profile.can_upgrade(&"wave_shield"))
	assert_false(Profile.upgrade(&"wave_shield"))
	assert_eq(Profile.gold, 100)
	assert_eq(Profile.level_of(&"wave_shield"), 1)


func test_stops_at_max_level() -> void:
	Profile.set_gold(100000)
	for i: int in 10:
		Profile.upgrade(&"repair_works")
	assert_eq(Profile.level_of(&"repair_works"), BuildingData.MAX_LEVEL)
	assert_true(Profile.is_max_level(&"repair_works"))
	assert_eq(Profile.upgrade_cost(&"repair_works"), 0)


func test_multiplier_makes_buildings_cost_differently() -> void:
	assert_gt(Profile.upgrade_cost(&"shipyard"), Profile.upgrade_cost(&"wave_shield"))
	assert_eq(Profile.upgrade_cost(&"nothing"), 0)


func test_payout_adds_victory_bonus_only_when_won() -> void:
	var bonus: int = Profile.economy_rules.victory_bonus
	assert_eq(Profile.payout_for(300, false), 300)
	assert_eq(Profile.payout_for(300, true), 300 + bonus)
	assert_eq(Profile.payout_for(-5, false), 0)
	var before: int = Profile.gold
	assert_eq(Profile.settle_battle(120, true), 120 + bonus)
	assert_eq(Profile.gold, before + 120 + bonus)


func test_save_and_load_round_trip() -> void:
	Profile.set_gold(1234)
	Profile.building_levels[&"tidal_power"] = 4
	assert_true(Profile.save(TEMP_PATH, true))
	Profile.reset_to_new()
	assert_true(Profile.load_saved(TEMP_PATH))
	assert_eq(Profile.gold, 1234)
	assert_eq(Profile.level_of(&"tidal_power"), 4)


func test_apply_ignores_bad_values() -> void:
	Profile.apply_dictionary({"gold": "abc", "levels": {"wave_shield": 99, "unknown": 3, "shipyard": "x"}})
	assert_eq(Profile.gold, Profile.NEW_PLAYER_GOLD)
	assert_eq(Profile.level_of(&"wave_shield"), BuildingData.MAX_LEVEL)
	assert_eq(Profile.level_of(&"shipyard"), 1)
	assert_false(Profile.building_levels.has(&"unknown"))


func test_economy_tracks_earned_but_not_refunds() -> void:
	var economy: Economy = Economy.new()
	add_child_autofree(economy)
	economy.reset(200)
	economy.earn(30)
	economy.receive_refund(50)
	economy.earn(10)
	assert_eq(economy.steel, 290)
	assert_eq(economy.earned, 40)
	economy.reset(100)
	assert_eq(economy.earned, 0)


func test_battle_uses_profile_levels() -> void:
	Profile.building_levels[&"shipyard"] = 5
	var battle: BattleController = load("res://battle/battle.tscn").instantiate()
	add_child_autofree(battle)
	await get_tree().process_frame
	assert_eq(battle.layout.building_level(&"shipyard"), 5)
	assert_eq(battle.layout.building_level(&"wave_shield"), 1)
