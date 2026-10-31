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
