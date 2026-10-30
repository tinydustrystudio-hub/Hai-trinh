extends GutTest
## Vòng đời trận: không có lô cốt thì thua đúng như mong đợi; Độ Nổi đủ lớn thì chạy đủ 5 đợt rồi thắng.

const BATTLE_SCENE: PackedScene = preload("res://battle/battle.tscn")
const STEP: float = 0.1
const MAX_SECONDS: float = 900.0

var _battle: BattleController
var _waves_started: Array[int] = []


func _on_wave_started(index: int, _total: int) -> void:
	_waves_started.append(index)


func before_each() -> void:
	TranslationServer.set_locale("vi")
	_waves_started.clear()
	_battle = add_child_autofree(BATTLE_SCENE.instantiate())
	Events.wave_started.connect(_on_wave_started)
	watch_signals(Events)


func after_each() -> void:
	Events.wave_started.disconnect(_on_wave_started)


func _run_until_over() -> float:
	var elapsed: float = 0.0
	while not _battle.is_over() and elapsed < MAX_SECONDS:
		_battle.step(STEP)
		elapsed += STEP
	return elapsed


func test_starts_preparing() -> void:
	assert_eq(_battle.state, BattleController.State.PREPARING)
	assert_eq(_battle.buoyancy.value, 20)
	assert_eq(_battle.hud.buoyancy_text(), tr(&"HUD_BUOYANCY") % [20, 20])


func test_loses_without_towers() -> void:
	_run_until_over()
	assert_eq(_battle.state, BattleController.State.LOST)
	assert_eq(_battle.buoyancy.value, 0)
	assert_signal_emitted_with_parameters(Events, "battle_ended", [false])
	# Đợt 1 lọt 6 Độ Nổi; đợt 2 có 8 Xuồng Cướp (8) và 3 Ca Nô Cảm Tử (9): chìm ở đợt 2.
	assert_eq(_waves_started, [0, 1])
	assert_almost_eq(_battle.island.tilt_degrees(), Buoyancy.MAX_TILT_DEGREES, 0.0001)
	# Bệ là phao riêng, không nghiêng theo đảo.
	assert_eq(_battle.island.pads[0].global_position, _battle.layout.pad_positions[0])
	assert_true(_battle.hud.result_panel.visible)
	assert_eq(_battle.hud.result_panel.title_text(), "Đảo đã chìm")


func test_wins_after_five_waves_when_island_survives() -> void:
	var sturdy: MapLayout = _battle.layout.duplicate()
	sturdy.starting_buoyancy = 1000
	_battle.layout = sturdy
	_battle.start_battle()
	_waves_started.clear()
	_run_until_over()
	assert_eq(_battle.state, BattleController.State.WON)
	assert_eq(_waves_started, [0, 1, 2, 3, 4])
	# Không lô cốt: mọi địch đều lọt.
	assert_eq(_battle.buoyancy.value, 1000 - (6 + 17 + 12 + 26 + 34))
	assert_eq(_battle.enemy_pool.active_count(), 0)
	assert_signal_emitted_with_parameters(Events, "battle_ended", [true])


func test_retry_resets() -> void:
	_run_until_over()
	_battle.retry()
	assert_eq(_battle.state, BattleController.State.PREPARING)
	assert_eq(_battle.buoyancy.value, 20)
	assert_eq(_battle.enemy_pool.active_count(), 0)
	assert_false(_battle.hud.result_panel.visible)


func test_pause_and_fast_forward_only_change_time_scale() -> void:
	_battle.toggle_fast()
	assert_eq(Engine.time_scale, 2.0)
	_battle.set_paused(true)
	assert_eq(Engine.time_scale, 0.0)
	_battle.set_paused(false)
	assert_eq(Engine.time_scale, 2.0)
	_battle.toggle_fast()
	assert_eq(Engine.time_scale, 1.0)
	assert_eq(_battle.state, BattleController.State.PREPARING)


func test_max_enemies_on_screen_within_budget() -> void:
	var sturdy: MapLayout = _battle.layout.duplicate()
	sturdy.starting_buoyancy = 1000
	_battle.layout = sturdy
	_battle.start_battle()
	var peak: int = 0
	var elapsed: float = 0.0
	while not _battle.is_over() and elapsed < MAX_SECONDS:
		_battle.step(STEP)
		elapsed += STEP
		peak = maxi(peak, _battle.enemy_pool.active_count())
	assert_lte(peak, 60)
