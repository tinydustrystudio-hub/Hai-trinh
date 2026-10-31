class_name BattleBot
extends RefCounted
## Người chơi giả để thử cân bằng (kế hoạch bước 12). Chỉ dùng trong test và công cụ đo, không vào bản xuất.
## - NAIVE: chỉ đặt Súng Máy theo thứ tự bệ mỗi khi đủ Thép; không nâng cấp, không MEGA.
## - SMART: đặt lô cốt ở bệ phủ được nhiều đoạn luồng nhất của đợt sắp tới; luồng có Ca Nô Cảm Tử hoặc Cua
##   cần thêm Súng Máy và một Lô Cốt Keo; nâng cấp lô cốt của các luồng sắp tới, chọn nhánh, kích MEGA khi
##   có từ 3 địch trong tầm.

enum Strategy { NAIVE, SMART }

## Bot nghĩ lại mỗi chừng này giây (người thật không chạm liên tục).
const THINK_INTERVAL: float = 1.0

var battle: BattleController
var strategy: Strategy
var actions: int = 0

var _think_left: float = 0.0
# Nạp lúc chạy, không dùng const preload (cùng lý do với tests/test_data.gd).
var MG: TowerData
var GLUE: TowerData
var RAM: EnemyData
var CRAB: EnemyData


func _init(target: BattleController, chosen: Strategy) -> void:
	battle = target
	strategy = chosen
	MG = load("res://data/towers/machine_gun.tres")
	GLUE = load("res://data/towers/glue_sprayer.tres")
	RAM = load("res://data/enemies/ram_drone.tres")
	CRAB = load("res://data/enemies/spiked_crab.tres")


func tick(delta: float) -> void:
	_think_left -= delta
	if _think_left > 0.0:
		return
	_think_left = THINK_INTERVAL
	match strategy:
		Strategy.NAIVE:
			_naive()
		Strategy.SMART:
			_smart()


## Chạy trọn trận; trả số giây đã chạy.
static func play(target: BattleController, chosen: Strategy, step: float = 0.1, limit: float = 900.0) -> float:
	var bot: BattleBot = BattleBot.new(target, chosen)
	var elapsed: float = 0.0
	while not target.is_over() and elapsed < limit:
		bot.tick(step)
		target.step(step)
		elapsed += step
	return elapsed


func _naive() -> void:
	for pad: TowerPad in battle.island.pads:
		if not pad.occupied and battle.economy.can_afford(MG.level(1).steel_cost):
			if battle.build_tower(pad, MG) != null:
				actions += 1
			return


func _smart() -> void:
	var wave: Wave = _next_wave()
	if wave == null:
		return
	# 1. Mỗi luồng của đợt sắp tới cần một Súng Máy; luồng có Ca Nô hoặc Cua cần hai Súng Máy và một Keo.
	for lane_index: int in wave.lane_indices():
		var lane: Lane = battle.lanes[lane_index]
		var dangerous: bool = _wave_has(wave, RAM, lane_index) or _wave_has(wave, CRAB, lane_index)
		# Chưa đủ Thép cho lô cốt luồng cần thì để dành, không đem đi nâng cấp.
		if _towers_covering(lane, MG).is_empty():
			_build_near(lane, MG)
			return
		if dangerous and _towers_covering(lane, GLUE).is_empty():
			_build_near(lane, GLUE)
			return
		if dangerous and _towers_covering(lane, MG).size() < 2:
			_build_near(lane, MG)
			return
	# 2. Nâng lô cốt của các luồng sắp tới, Súng Máy trước.
	for lane_index: int in wave.lane_indices():
		for tower: Tower in _towers_covering(battle.lanes[lane_index], MG) + _towers_covering(battle.lanes[lane_index], GLUE):
			if tower.can_level_up() and battle.upgrade_tower(tower):
				actions += 1
				return
			if tower.needs_branch():
				var chosen: TowerBranch = tower.data.branches[1 if _wave_has(wave, CRAB, lane_index) else 0]
				if battle.choose_branch(tower, chosen):
					actions += 1
					return
	# 3. Thừa Thép thì thêm Súng Máy thứ hai cho luồng đông nhất.
	var busiest: int = _busiest_lane(wave)
	if busiest >= 0 and _towers_covering(battle.lanes[busiest], MG).size() < 2:
		_build_near(battle.lanes[busiest], MG)
	# 4. MEGA khi có từ 3 địch trong tầm.
	for tower: Tower in battle.towers:
		if tower.overload.is_ready() and _enemies_in_range(tower) >= 3:
			battle.activate_mega(tower)
			actions += 1


func _next_wave() -> Wave:
	var data: WaveData = battle.wave_data
	var index: int = battle.spawner.wave_index
	if index >= data.wave_count():
		return null
	return data.waves[index]


func _wave_has(wave: Wave, enemy: EnemyData, lane_index: int) -> bool:
	for group: SpawnGroup in wave.groups:
		if group.enemy == enemy and group.lane_index == lane_index:
			return true
	return false


func _busiest_lane(wave: Wave) -> int:
	var best: int = -1
	var most: int = 0
	for group: SpawnGroup in wave.groups:
		if group.count > most:
			most = group.count
			best = group.lane_index
	return best


func _towers_covering(lane: Lane, data: TowerData) -> Array[Tower]:
	var result: Array[Tower] = []
	for tower: Tower in battle.towers:
		if tower.data == data and lane.distance_to(tower.global_position) <= tower.range_units():
			result.append(tower)
	return result


## Đặt lô cốt ở bệ trống trong tầm luồng cần giữ, ưu tiên bệ phủ được nhiều đoạn luồng nhất của cả đợt
## sắp tới (bệ trên mỏm bến giữa hai luồng giữ được cả hai).
func _build_near(lane: Lane, data: TowerData) -> bool:
	if not battle.economy.can_afford(data.level(1).steel_cost):
		return false
	var reach: float = data.level(1).range_units()
	var wave: Wave = _next_wave()
	var best: TowerPad = null
	var best_score: int = 0
	for pad: TowerPad in battle.island.pads:
		if pad.occupied or _coverage(pad, lane, reach) == 0:
			continue
		# Luồng cần giữ nặng gấp ba các luồng khác của đợt.
		var score: int = _coverage(pad, lane, reach) * 2
		for lane_index: int in wave.lane_indices():
			score += _coverage(pad, battle.lanes[lane_index], reach)
		if score > best_score:
			best = pad
			best_score = score
	if best == null:
		return false
	if battle.build_tower(best, data) == null:
		return false
	actions += 1
	return true


## Số điểm (trong 60 điểm cách đều) của luồng nằm trong tầm reach của bệ.
func _coverage(pad: TowerPad, lane: Lane, reach: float) -> int:
	var cover: int = 0
	var samples: int = 60
	for k: int in samples:
		var point: Vector3 = lane.position_at(lane.length() * float(k) / float(samples - 1))
		if Vector2(point.x - pad.global_position.x, point.z - pad.global_position.z).length() <= reach:
			cover += 1
	return cover


func _enemies_in_range(tower: Tower) -> int:
	var count: int = 0
	var reach: float = tower.range_units()
	for enemy: Enemy in battle.enemy_pool.active:
		if Vector2(enemy.position.x - tower.global_position.x, enemy.position.z - tower.global_position.z).length() <= reach:
			count += 1
	return count
