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
	# Đợt 1 lọt 12 Độ Nổi; đợt 2 có 16 Xuồng Cướp và 6 Ca Nô Cảm Tử: chìm ở đợt 2.
	assert_eq(_waves_started, [0, 1])
	assert_almost_eq(_battle.island.tilt_degrees(), Buoyancy.MAX_TILT_DEGREES, 0.0001)
	# Bệ trên đảo vệ tinh là phao riêng, chỉ dập dìu nhẹ theo sóng; bệ trên mỏm bến nghiêng theo pháo đài.
	for i: int in _battle.layout.pad_count():
		var pad: TowerPad = _battle.island.pads[i]
		if _battle.layout.is_satellite_pad(i) or _battle.layout.platform_index_of_pad(i) >= 0:
			var flat: Vector3 = pad.global_position - _battle.layout.pad_positions[i]
			flat.y = 0.0
			assert_lt(flat.length(), 0.5)
		else:
			assert_ne(pad.global_position, _battle.layout.pad_positions[i])
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
	assert_eq(_battle.buoyancy.value, 1000 - 2 * (6 + 17 + 12 + 26 + 34))
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


func test_lane_shows_only_in_the_ten_seconds_before_its_enemies() -> void:
	# Đợt 1 chỉ đi luồng Bắc, chờ first_wave_delay (10 giây): luồng Bắc và đèn báo của nó bật ngay.
	var island: Island = _battle.island
	assert_true(_battle.lanes[0].is_warning())
	assert_true(island.beacons.is_active(0))
	for i: int in range(1, _battle.lanes.size()):
		assert_false(_battle.lanes[i].is_warning(), "luồng %d không có địch đợt 1" % i)
		assert_false(island.beacons.is_active(i))
	# Địch đầu tiên ra thì tắt.
	var waited: float = 0.0
	while _battle.enemy_pool.active_count() == 0 and waited < 20.0:
		_battle.step(0.25)
		waited += 0.25
	assert_gt(_battle.enemy_pool.active_count(), 0)
	assert_false(_battle.lanes[0].is_warning())
	assert_false(island.beacons.is_active(0))


func test_seconds_until_lane_counts_group_delay() -> void:
	# Đợt 2: luồng Bắc ra ngay khi đợt bắt đầu, luồng Đông chậm hơn theo delay của nhóm.
	var spawner: WaveSpawner = _battle.spawner
	var east_delay: float = INF
	for group: SpawnGroup in _battle.wave_data.waves[1].groups:
		if group.lane_index == 1:
			east_delay = minf(east_delay, group.delay)
	while spawner.wave_index < 1 or spawner.state != WaveSpawner.State.WAITING:
		_battle.step(0.25)
	var wait: float = spawner.seconds_until_next_wave()
	assert_almost_eq(spawner.seconds_until_lane(0), wait, 0.0001)
	assert_almost_eq(spawner.seconds_until_lane(1), wait + east_delay, 0.0001)
	assert_eq(spawner.seconds_until_lane(2), -1.0, "đợt 2 không đi luồng Tây")

