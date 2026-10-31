class_name BattleBot
extends RefCounted
## Người chơi giả để thử cân bằng (kế hoạch bước 12). Chỉ dùng trong test và công cụ đo, không vào bản xuất.
## - NAIVE: chỉ đặt Súng Máy theo thứ tự bệ mỗi khi đủ Thép; không nâng cấp, không MEGA.
## - SMART: chuẩn bị trước một đợt; đặt lô cốt ở bệ phủ được nhiều đoạn luồng nhất; luồng có Ca Nô Cảm Tử
##   hoặc Cua cần thêm Súng Máy, một Lô Cốt Keo và Súng Máy cấp cao; nâng cấp, chọn nhánh, kích MEGA khi
##   có từ 3 địch trong tầm (xem thứ tự ưu tiên trong _smart()).

enum Strategy { NAIVE, SMART }

## Bot nghĩ lại mỗi chừng này giây (người thật không chạm liên tục).
const THINK_INTERVAL: float = 1.0
## Luồng có từ chừng này địch trong một đợt thì cần hai Súng Máy.
const BUSY_LANE: int = 10
## Súng Máy giữ luồng có Ca Nô hoặc Cua được nâng tới cấp này trước khi lo các việc khác.
const DANGER_LEVEL: int = 3

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
	# MEGA khi có từ 3 địch trong tầm (luôn xét trước, kể cả lúc đang để dành Thép).
	for tower: Tower in battle.towers:
		if tower.overload.is_ready() and _enemies_in_range(tower) >= 3:
			battle.activate_mega(tower)
			actions += 1
	# Người chơi thật thấy đợt kế qua đèn báo, hoặc nhớ từ lần chơi trước, nên chuẩn bị trước một đợt.
	# Thứ tự ưu tiên; bước nào thiếu Thép thì để dành, không làm bước sau:
	# 1. đợt đang đánh: đủ lô cốt cho mọi luồng;
	# 2. đợt kế: mỗi luồng ít nhất một Súng Máy;
	# 3. Súng Máy giữ luồng có Ca Nô hoặc Cua (đợt này và đợt kế) lên tới DANGER_LEVEL;
	# 4. đợt kế: đủ lô cốt cho mọi luồng;
	# 5. nâng các lô cốt còn lại của đợt đang đánh, chọn nhánh;
	# 6. thêm Súng Máy thứ ba cho luồng đông nhất.
	var plans: Array[Wave] = _waves_to_prepare()
	if _prepare(plans[0], true):
		return
	if plans.size() > 1 and _prepare(plans[1], false):
		return
	for planned: Wave in plans:
		for lane_index: int in planned.lane_indices():
			if not _dangerous(planned, lane_index):
				continue
			for tower: Tower in _towers_covering(battle.lanes[lane_index], MG):
				if tower.can_level_up() and tower.level < DANGER_LEVEL:
					if battle.upgrade_tower(tower):
						actions += 1
					return
	if plans.size() > 1 and _prepare(plans[1], true):
		return
	for lane_index: int in wave.lane_indices():
		for tower: Tower in _towers_covering(battle.lanes[lane_index], MG) + _towers_covering(battle.lanes[lane_index], GLUE):
			if tower.can_level_up():
				if battle.upgrade_tower(tower):
					actions += 1
				return
			if tower.needs_branch():
				var chosen: TowerBranch = tower.data.branches[1 if _wave_has(wave, CRAB, lane_index) else 0]
				if battle.choose_branch(tower, chosen):
					actions += 1
				return
	var busiest: int = _busiest_lane(wave)
	if busiest >= 0 and _towers_covering(battle.lanes[busiest], MG).size() < 3:
		_build_near(battle.lanes[busiest], MG, wave)


## Xây lô cốt còn thiếu cho các luồng của một đợt. full = false: chỉ cần mỗi luồng một Súng Máy;
## full = true: luồng đông hoặc có Ca Nô, Cua cần hai Súng Máy, luồng có Ca Nô, Cua thêm một Keo.
## Trả true nếu đã xây, hoặc đang thiếu Thép cho lô cốt cần xây (để dành). Hết bệ trống trong tầm thì bỏ qua.
func _prepare(planned: Wave, full: bool) -> bool:
	for lane_index: int in planned.lane_indices():
		var lane: Lane = battle.lanes[lane_index]
		var dangerous: bool = _dangerous(planned, lane_index)
		var guns: int = 1
		if full and (dangerous or _lane_count(planned, lane_index) >= BUSY_LANE):
			guns = 2
		var missing: TowerData = null
		if _towers_covering(lane, MG).size() < guns:
			missing = MG
		elif full and dangerous and _towers_covering(lane, GLUE).is_empty():
			missing = GLUE
		if missing != null and _free_pad_near(lane, missing) != null:
			_build_near(lane, missing, planned)
			return true
	return false


func _dangerous(wave: Wave, lane_index: int) -> bool:
	return _wave_has(wave, RAM, lane_index) or _wave_has(wave, CRAB, lane_index)


## Đợt đang đánh (hoặc sắp tới) và đợt sau nó.
func _waves_to_prepare() -> Array[Wave]:
	var result: Array[Wave] = []
	var data: WaveData = battle.wave_data
	var index: int = battle.spawner.wave_index
	for i: int in range(index, mini(index + 2, data.wave_count())):
		result.append(data.waves[i])
	return result


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


func _lane_count(wave: Wave, lane_index: int) -> int:
	var total: int = 0
	for group: SpawnGroup in wave.groups:
		if group.lane_index == lane_index:
			total += group.count
	return total


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
func _build_near(lane: Lane, data: TowerData, wave: Wave) -> bool:
	if not battle.economy.can_afford(data.level(1).steel_cost):
		return false
	var reach: float = data.level(1).range_units()
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


func _free_pad_near(lane: Lane, data: TowerData) -> TowerPad:
	var reach: float = data.level(1).range_units()
	for pad: TowerPad in battle.island.pads:
		if not pad.occupied and _coverage(pad, lane, reach) > 0:
			return pad
	return null


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
