class_name WaveSpawner
extends Node
## Sinh địch theo đợt, theo nhóm và theo giờ. Một đợt xong khi đã sinh hết và không còn con nào
## trên biển; khi đó nghỉ rest_after giây rồi sang đợt kế. Trong lúc chờ thì báo đợt sắp tới cho HUD.
## Không tự chạy: BattleController gọi advance() mỗi khung (thời gian đã nhân Engine.time_scale).

signal spawn_requested(enemy: EnemyData, lane_index: int)
signal wave_started(index: int, total: int)
signal wave_cleared(index: int)
signal wave_incoming(index: int, lanes: PackedInt32Array, seconds: float)
signal all_waves_cleared

enum State { IDLE, WAITING, SPAWNING, FINISHED }

## Báo đợt sắp tới cách nhau bao lâu (giây) trong lúc chờ.
const INCOMING_NOTICE_INTERVAL: float = 1.0

var wave_data: WaveData
var state: State = State.IDLE
## Đợt hiện tại (0 = đợt đầu); trong lúc chờ là đợt sắp tới.
var wave_index: int = 0
## Số địch đã sinh mà chưa bị hạ hoặc lọt.
var alive: int = 0

var _wave_time: float = 0.0
var _wait_left: float = 0.0
var _notice_left: float = 0.0
var _spawned: PackedInt32Array = PackedInt32Array()


func start(data: WaveData) -> void:
	wave_data = data
	wave_index = 0
	alive = 0
	_begin_wait(data.first_wave_delay)


func stop() -> void:
	state = State.IDLE


func total_waves() -> int:
	return wave_data.wave_count() if wave_data != null else 0


## Số giây còn lại trước đợt kế (chỉ có nghĩa khi đang chờ).
func seconds_until_next_wave() -> float:
	return _wait_left if state == State.WAITING else 0.0


## Số giây tới khi con địch đầu tiên của đợt hiện tại (hoặc đợt sắp tới, nếu đang chờ) xuất hiện ở luồng
## lane_index. Trả về −1 nếu đợt đó không đi luồng này, địch đã xuất hiện, hoặc không còn đợt nào.
func seconds_until_lane(lane_index: int) -> float:
	if wave_data == null or (state != State.WAITING and state != State.SPAWNING):
		return -1.0
	var wave: Wave = wave_data.waves[wave_index]
	var first: float = INF
	for g: int in wave.groups.size():
		var group: SpawnGroup = wave.groups[g]
		if group.lane_index != lane_index:
			continue
		if state == State.SPAWNING and _spawned[g] > 0:
			return -1.0
		first = minf(first, group.delay)
	if first == INF:
		return -1.0
	if state == State.WAITING:
		return maxf(_wait_left, 0.0) + first
	return maxf(first - _wave_time, 0.0)


## Gọi khi một địch đã sinh bị hạ hoặc lọt.
func notify_enemy_removed() -> void:
	alive = maxi(alive - 1, 0)


## Gọi đợt kế ngay khi đang chờ.
func call_next_wave_now() -> void:
	if state == State.WAITING:
		_wait_left = 0.0


func advance(delta: float) -> void:
	match state:
		State.WAITING:
			_wait_left -= delta
			_notice_left -= delta
			if _wait_left <= 0.0:
				# Phần thời gian dư của khung này tính luôn vào đợt mới, để khung dài (tua ×2) không làm lệch nhịp.
				_begin_wave(-_wait_left)
			elif _notice_left <= 0.0:
				_notice_left = INCOMING_NOTICE_INTERVAL
				_announce()
		State.SPAWNING:
			_wave_time += delta
			_spawn_due()
			if _all_spawned() and alive == 0:
				_finish_wave()


func _begin_wait(seconds: float) -> void:
	state = State.WAITING
	_wait_left = seconds
	_notice_left = INCOMING_NOTICE_INTERVAL
	_announce()


func _announce() -> void:
	var wave: Wave = wave_data.waves[wave_index]
	wave_incoming.emit(wave_index, wave.lane_indices(), maxf(_wait_left, 0.0))


func _begin_wave(elapsed: float) -> void:
	state = State.SPAWNING
	_wave_time = elapsed
	var wave: Wave = wave_data.waves[wave_index]
	_spawned.resize(wave.groups.size())
	_spawned.fill(0)
	wave_started.emit(wave_index, total_waves())
	_spawn_due()


func _spawn_due() -> void:
	var wave: Wave = wave_data.waves[wave_index]
	for g: int in wave.groups.size():
		var group: SpawnGroup = wave.groups[g]
		while _spawned[g] < group.count and _wave_time >= group.delay + group.interval * float(_spawned[g]):
			_spawned[g] += 1
			alive += 1
			spawn_requested.emit(group.enemy, group.lane_index)


func _all_spawned() -> bool:
	var wave: Wave = wave_data.waves[wave_index]
	for g: int in wave.groups.size():
		if _spawned[g] < wave.groups[g].count:
			return false
	return true


func _finish_wave() -> void:
	var finished: int = wave_index
	var rest: float = wave_data.waves[finished].rest_after
	wave_cleared.emit(finished)
	if finished + 1 >= total_waves():
		state = State.FINISHED
		all_waves_cleared.emit()
		return
	wave_index = finished + 1
	_begin_wait(rest)
