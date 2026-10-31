extends GutTest
## Thép (GDD mục 3.1, kế hoạch mục 5.4): khởi đầu, thưởng hạ địch, +20 đầu đợt, trừ khi xây, hoàn 70% khi bán.

var _economy: Economy


func before_each() -> void:
	_economy = add_child_autofree(Economy.new())
	watch_signals(_economy)
	_economy.reset(200)


func test_starts_with_layout_steel() -> void:
	assert_eq(_economy.steel, 200)
	assert_signal_emitted_with_parameters(_economy, "changed", [200])


func test_wave_bonus_from_data() -> void:
	_economy.on_wave_started()
	assert_eq(_economy.steel, 220)


func test_spend_and_refuse_when_short() -> void:
	assert_true(_economy.spend(70))
	assert_eq(_economy.steel, 130)
	assert_false(_economy.spend(131))
	assert_eq(_economy.steel, 130)
	assert_true(_economy.can_afford(130))
	assert_false(_economy.spend(-5))


func test_earn_kill_rewards() -> void:
	_economy.earn(5)
	_economy.earn(40)
	assert_eq(_economy.steel, 245)
	_economy.earn(0)
	_economy.earn(-10)
	assert_eq(_economy.steel, 245)


func test_refund_seventy_percent() -> void:
	assert_eq(_economy.refund_for(70), 49)
	assert_eq(_economy.refund_for(70 + 60 + 90), 154)
	assert_eq(_economy.refund_for(0), 0)


func test_data_values() -> void:
	var data: EconomyData = load("res://data/economy.tres")
	assert_eq(data.wave_bonus, 20)
	assert_almost_eq(data.sell_refund, 0.7, 0.0001)


func test_island_use_cost_rises_by_fifty() -> void:
	# Đảo tự đặt thứ 1 là 200, mỗi đảo tiếp theo +50 (người duyệt chốt 31/10).
	var rules: EconomyData = load("res://data/economy.tres")
	assert_eq(rules.island_use_cost(1), 200)
	assert_eq(rules.island_use_cost(2), 250)
	assert_eq(rules.island_use_cost(4), 350)
	assert_eq(rules.island_use_total(0), 0)
	assert_eq(rules.island_use_total(4), 200 + 250 + 300 + 350)


func test_island_move_cost_is_half_cheapest_tower() -> void:
	var rules: EconomyData = load("res://data/economy.tres")
	var cheapest: int = 9999
	for path: String in ["machine_gun", "glue_sprayer", "light_beam"]:
		var data: TowerData = load("res://data/towers/%s.tres" % path)
		cheapest = mini(cheapest, data.level(1).steel_cost)
	assert_eq(cheapest, 60)
	assert_eq(rules.island_move_cost(cheapest), 30)
	assert_eq(rules.island_move_cost(1), 1, "tối thiểu 1")


func test_island_buy_cost_starts_at_250_and_rises_by_fifty() -> void:
	# Đảo mua thêm thứ nhất (đảo thứ 5 của màn 1) là 250, mỗi đảo sau +50 (người duyệt chốt 31/10).
	var rules: EconomyData = load("res://data/economy.tres")
	assert_eq(rules.island_buy_cost(1), 250)
	assert_eq(rules.island_buy_cost(2), 300)
	assert_eq(rules.island_buy_cost(4), 400)
	assert_eq(rules.island_buy_cost(0), 250, "không âm")


func test_building_upgrade_cost_formula() -> void:
	# Số tạm (người duyệt 31/10: dùng số tạm): 200 → ×1,6 mỗi cấp, làm tròn tới 10.
	var rules: EconomyData = load("res://data/economy.tres")
	assert_eq(rules.building_upgrade_cost(1), 0)
	assert_eq(rules.building_upgrade_cost(2), 200)
	assert_eq(rules.building_upgrade_cost(3), 320)
	assert_eq(rules.building_upgrade_cost(4), 510)
	assert_eq(rules.building_upgrade_cost(5), 820)
	assert_eq(rules.building_upgrade_cost(3, 1.5), 480, "hệ số riêng của công trình")
	assert_eq(rules.building_total_cost(5), 200 + 320 + 510 + 820)
	assert_eq(rules.building_total_cost(1), 0)
