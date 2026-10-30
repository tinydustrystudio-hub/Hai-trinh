extends GutTest
## Bộ sinh đợt: chờ đúng giờ, sinh đúng nhịp, chỉ xong đợt khi đã dọn sạch, nghỉ rồi sang đợt kế.

const SKIFF: EnemyData = preload("res://data/enemies/raider_skiff.tres")
const RAM: EnemyData = preload("res://data/enemies/ram_drone.tres")

var _spawner: WaveSpawner
var _spawns: Array[Array] = []


func _group(enemy: EnemyData, count: int, interval: float, lane: int, delay: float) -> SpawnGroup:
	var group: SpawnGroup = SpawnGroup.new()
	group.enemy = enemy
	group.count = count
	group.interval = interval
	group.lane_index = lane
	group.delay = delay
	return group


func _data() -> WaveData:
	var data: WaveData = WaveData.new()
	data.first_wave_delay = 5.0
	var first: Wave = Wave.new()
	first.groups = [_group(SKIFF, 3, 1.5, 0, 0.0)]
	first.rest_after = 4.0
	var second: Wave = Wave.new()
	second.groups = [_group(SKIFF, 2, 1.0, 1, 0.0), _group(RAM, 1, 0.0, 2, 2.0)]
	data.waves = [first, second]
	return data


func _on_spawn(enemy: EnemyData, lane: int) -> void:
	_spawns.append([enemy, lane])


func _advance(seconds: float, step: float = 0.05) -> void:
	var left: float = seconds
	while left > 0.0001:
		var dt: float = minf(step, left)
		_spawner.advance(dt)
		left -= dt


func before_each() -> void:
	_spawns.clear()
	_spawner = add_child_autofree(WaveSpawner.new())
	_spawner.spawn_requested.connect(_on_spawn)
	watch_signals(_spawner)
	_spawner.start(_data())


func test_waits_before_first_wave() -> void:
	assert_eq(_spawner.state, WaveSpawner.State.WAITING)
	assert_signal_emitted(_spawner, "wave_incoming")
	_advance(4.9)
	assert_eq(_spawns.size(), 0)
	_advance(0.2)
	assert_signal_emitted_with_parameters(_spawner, "wave_started", [0, 2])
	assert_eq(_spawns.size(), 1)


func test_spawns_at_interval() -> void:
	_advance(5.01)
	assert_eq(_spawns.size(), 1)
	_advance(1.4)
	assert_eq(_spawns.size(), 1)
	_advance(0.2)
	assert_eq(_spawns.size(), 2)
	_advance(1.5)
	assert_eq(_spawns.size(), 3)
	_advance(10.0)
	assert_eq(_spawns.size(), 3, "đợt 1 chỉ có 3 con")
	assert_eq(_spawner.alive, 3)


func test_wave_clears_only_when_enemies_gone() -> void:
	_advance(10.0)
	assert_signal_not_emitted(_spawner, "wave_cleared")
	_spawner.notify_enemy_removed()
	_spawner.notify_enemy_removed()
	_advance(0.1)
	assert_signal_not_emitted(_spawner, "wave_cleared")
	_spawner.notify_enemy_removed()
	_advance(0.05)
	assert_signal_emitted_with_parameters(_spawner, "wave_cleared", [0])
	assert_eq(_spawner.state, WaveSpawner.State.WAITING)
	assert_eq(_spawner.wave_index, 1)
	assert_almost_eq(_spawner.seconds_until_next_wave(), 4.0, 0.0001)


func test_incoming_notice_names_next_lanes() -> void:
	_advance(10.0)
	for i: int in 3:
		_spawner.notify_enemy_removed()
	_advance(0.1)
	var params: Array = get_signal_parameters(_spawner, "wave_incoming")
	assert_eq(params[0], 1)
	assert_eq(Array(params[1]), [1, 2])


func test_runs_all_waves() -> void:
	_advance(10.0)
	for i: int in 3:
		_spawner.notify_enemy_removed()
	_advance(4.2)
	assert_signal_emitted_with_parameters(_spawner, "wave_started", [1, 2])
	_advance(3.0)
	assert_eq(_spawns.size(), 6)
	assert_eq(_spawns[5], [RAM, 2])
	for i: int in 3:
		_spawner.notify_enemy_removed()
	_advance(0.1)
	assert_signal_emitted(_spawner, "all_waves_cleared")
	assert_eq(_spawner.state, WaveSpawner.State.FINISHED)


func test_call_next_wave_early() -> void:
	_spawner.call_next_wave_now()
	_advance(0.05)
	assert_signal_emitted(_spawner, "wave_started")


func test_large_step_spawns_everything_due() -> void:
	_advance(20.0, 20.0)
	assert_eq(_spawns.size(), 3)
