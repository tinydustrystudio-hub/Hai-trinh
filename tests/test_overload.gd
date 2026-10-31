extends GutTest
## Thanh Quá tải (GDD mục 3.1–3.2, kế hoạch mục 5.4): Nạp → Sẵn sàng → MEGA → Làm mát → Nạp;
## Súng Máy đầy sau đúng 14 giây bắn liên tục; Lô Cốt Keo đầy sau 12 giây khi 3 địch dính keo;
## hệ số ×3 (hỗ trợ ×1,5) khi MEGA, 0,2 khi làm mát; MEGA lúc địch dính keo xóa được cả cụm.

const BATTLE_SCENE: PackedScene = preload("res://battle/battle.tscn")
const MG: TowerData = preload("res://data/towers/machine_gun.tres")
const GLUE: TowerData = preload("res://data/towers/glue_sprayer.tres")
const SKIFF: EnemyData = preload("res://data/enemies/raider_skiff.tres")
const CRAB: EnemyData = preload("res://data/enemies/spiked_crab.tres")
## Bước 0,25 giây cộng không sai số dấu phẩy động.
const STEP: float = 0.25

var _pool: EnemyPool
var _lane: Lane


func before_each() -> void:
	_lane = Lane.new()
	_lane.setup(0, PackedVector3Array([Vector3(-40, 0, 0), Vector3(40, 0, 0)]), &"LANE_EAST")
	add_child_autofree(_lane)
	_pool = add_child_autofree(EnemyPool.new())


func _tower(script: GDScript, data: TowerData, at: Vector3) -> Tower:
	var pad: TowerPad = add_child_autofree(load("res://battle/map/tower_pad.tscn").instantiate())
	pad.position = at
	var tower: Tower = script.new()
	tower.setup(data, pad, _pool, null)
	pad.add_child(tower)
	return tower


func _enemy(data: EnemyData, distance: float) -> Enemy:
	var enemy: Enemy = _pool.acquire(data, _lane, distance)
	enemy.lateral_offset = 0.0
	enemy._place(0.0)
	return enemy


func _run(tower: Tower, seconds: float) -> void:
	for i: int in roundi(seconds / STEP):
		tower.tick(STEP)


func test_state_machine_and_multipliers() -> void:
	var overload: Overload = Overload.new(MG)
	watch_signals(overload)
	assert_eq(overload.state, Overload.State.CHARGING)
	assert_eq(overload.multiplier(), 1.0)
	assert_false(overload.activate(), "chưa đầy thì không kích được")
	overload.add_charge(0.6)
	overload.add_charge(0.6)
	assert_eq(overload.state, Overload.State.READY)
	assert_eq(overload.charge, 1.0)
	assert_signal_emitted(overload, "ready")
	overload.add_charge(1.0)
	assert_true(overload.activate())
	assert_eq(overload.multiplier(), 3.0)
	assert_signal_emitted(overload, "mega_started")
	overload.advance(4.75)
	assert_eq(overload.state, Overload.State.MEGA)
	overload.advance(0.5)
	assert_eq(overload.state, Overload.State.COOLDOWN, "MEGA kéo dài 5 giây")
	assert_almost_eq(overload.multiplier(), 0.2, 0.0001)
	assert_signal_emitted(overload, "mega_ended")
	overload.add_charge(1.0)
	assert_eq(overload.charge, 1.0, "làm mát không nạp")
	# Đã qua 0,25 giây làm mát ở nhịp trước; còn 6,75 giây.
	overload.advance(6.5)
	assert_eq(overload.state, Overload.State.COOLDOWN)
	overload.advance(0.5)
	assert_eq(overload.state, Overload.State.CHARGING, "làm mát 7 giây")
	assert_eq(overload.charge, 0.0, "làm mát xong thanh về 0")
	assert_eq(overload.multiplier(), 1.0)


func test_glue_mega_is_one_and_a_half() -> void:
	var overload: Overload = Overload.new(GLUE)
	overload.add_charge(1.0)
	overload.activate()
	assert_almost_eq(overload.multiplier(), 1.5, 0.0001)
	overload.advance(5.0)
	overload.advance(5.75)
	assert_eq(overload.state, Overload.State.COOLDOWN)
	overload.advance(0.5)
	assert_eq(overload.state, Overload.State.CHARGING, "Keo làm mát 6 giây")


func test_charge_formulas() -> void:
	assert_almost_eq(Overload.charge_per_hit(14.0, 5.0), 1.0 / 70.0, 0.000001)
	assert_almost_eq(Overload.glue_charge_rate(3, 12.0), 1.0 / 12.0, 0.000001)
	assert_almost_eq(Overload.glue_charge_rate(5, 12.0), 1.0 / 12.0, 0.000001, "tối đa 3 địch")
	assert_almost_eq(Overload.glue_charge_rate(1, 12.0), 1.0 / 36.0, 0.000001)
	assert_eq(Overload.glue_charge_rate(0, 12.0), 0.0)


func test_machine_gun_fills_after_fourteen_seconds() -> void:
	var gun: MachineGun = _tower(MachineGun, MG, Vector3(0, 0, 6))
	_enemy(CRAB, 40.0)
	_run(gun, 13.5)
	assert_eq(gun.overload.state, Overload.State.CHARGING)
	_run(gun, 0.5)
	assert_eq(gun.overload.state, Overload.State.READY, "đầy sau đúng 14 giây bắn liên tục")


func test_charge_stays_when_idle_and_through_upgrade() -> void:
	var gun: MachineGun = _tower(MachineGun, MG, Vector3(0, 0, 6))
	var crab: Enemy = _enemy(CRAB, 40.0)
	_run(gun, 7.0)
	var charge: float = gun.overload.charge
	assert_gt(charge, 0.4)
	_pool.release(crab)
	_run(gun, 10.0)
	assert_eq(gun.overload.charge, charge, "không tụt khi ngừng bắn")
	gun.level_up()
	assert_eq(gun.overload.charge, charge, "giữ nguyên khi nâng cấp")


func test_glue_fills_by_slowed_enemies() -> void:
	var glue: GlueSprayer = _tower(GlueSprayer, GLUE, Vector3(0, 0, 5))
	var crabs: Array[Enemy] = [_enemy(CRAB, 40.0), _enemy(CRAB, 40.5), _enemy(CRAB, 41.0)]
	# Giữ ba con Cua đứng yên trong vùng keo để đếm đúng 3 địch bị chậm.
	for i: int in roundi(11.75 / STEP):
		glue.tick(STEP)
		for crab: Enemy in crabs:
			crab.status.hold(1.0)
	assert_eq(glue.slowed_count, 3)
	assert_eq(glue.overload.state, Overload.State.CHARGING)
	glue.tick(STEP)
	glue.tick(STEP)
	assert_eq(glue.overload.state, Overload.State.READY, "3 địch dính keo: đầy sau 12 giây")


func test_cooldown_fires_at_twenty_percent() -> void:
	var gun: MachineGun = _tower(MachineGun, MG, Vector3(0, 0, 6))
	var crab: Enemy = _enemy(CRAB, 40.0)
	gun.overload.add_charge(1.0)
	gun.activate_mega()
	gun.shoot(crab)
	assert_almost_eq(CRAB.max_health - crab.health, 6.0 * 3.0 * 0.5, 0.001, "MEGA ×3")
	gun.overload.advance(5.0)
	var before: float = crab.health
	gun.shoot(crab)
	assert_almost_eq(before - crab.health, 6.0 * 0.2 * 0.5, 0.001, "làm mát 20% sức")


func test_mega_on_glued_cluster_wipes_it() -> void:
	# Bẫy keo (GDD mục 3.12): Lô Cốt Keo và Súng Máy phủ cùng đoạn luồng; đoàn Xuồng Cướp dính keo dồn cụm.
	var trap: Array = _glue_trap()
	var gun: MachineGun = trap[0]
	var cluster: Array[Enemy] = trap[2]
	gun.overload.add_charge(1.0)
	gun.activate_mega()
	_run_trap(trap, 5.0)
	var alive: int = 0
	for skiff: Enemy in cluster:
		if skiff.active:
			alive += 1
	assert_eq(alive, 0, "MEGA lúc địch dính keo xóa cả cụm")


func test_same_cluster_survives_without_mega() -> void:
	var trap: Array = _glue_trap()
	var cluster: Array[Enemy] = trap[2]
	_run_trap(trap, 5.0)
	var alive: int = 0
	for skiff: Enemy in cluster:
		if skiff.active:
			alive += 1
	assert_gt(alive, 0, "không MEGA thì không kịp xóa cả cụm trong 5 giây")


func _glue_trap() -> Array:
	var gun: MachineGun = _tower(MachineGun, MG, Vector3(0, 0, 6))
	var glue: GlueSprayer = _tower(GlueSprayer, GLUE, Vector3(2, 0, -5))
	var cluster: Array[Enemy] = []
	# Một đoàn 6 Xuồng Cướp như đợt 1. Súng Máy cấp 1: thường 12 phát mỗi con (14 giây cho cả đoàn),
	# MEGA ×3 còn 4 phát mỗi con (24 phát, chưa tới 5 giây).
	for i: int in 6:
		cluster.append(_enemy(SKIFF, 36.0 + float(i) * 0.8))
	return [gun, glue, cluster]


func _run_trap(trap: Array, seconds: float) -> void:
	for i: int in roundi(seconds / STEP):
		(trap[1] as Tower).tick(STEP)
		(trap[0] as Tower).tick(STEP)
		_pool.advance(STEP)


func test_mega_tray_and_tap_to_fire() -> void:
	var battle: BattleController = add_child_autofree(BATTLE_SCENE.instantiate())
	battle.economy.reset(1000)
	var towers: Array[Tower] = []
	for i: int in 5:
		towers.append(battle.build_tower(battle.island.pads[i], MG))
	for tower: Tower in towers:
		tower.overload.add_charge(1.0)
	var tray: MegaTray = battle.hud.mega_tray
	assert_eq(tray.queue.size(), 5)
	assert_eq(tray.visible_count(), 4, "tối đa 4 nút")
	assert_true(tray.buttons()[0].visible)
	assert_gte(MegaTray.BUTTON_SIZE, 120.0)
	tray.buttons()[0].pressed.emit()
	assert_eq(towers[0].overload.state, Overload.State.MEGA)
	assert_eq(tray.queue.size(), 4)
	assert_eq(tray.queue[0], towers[1], "xếp theo thứ tự đầy")
	assert_eq(battle.mega_bursts.full_count(), 1)


func test_tray_sits_in_bottom_right() -> void:
	var battle: BattleController = add_child_autofree(BATTLE_SCENE.instantiate())
	battle.economy.reset(1000)
	var tower: Tower = battle.build_tower(battle.island.pads[0], MG)
	tower.overload.add_charge(1.0)
	await wait_process_frames(2)
	var rect: Rect2 = battle.hud.mega_tray.buttons()[0].get_global_rect()
	var screen: Vector2 = battle.hud.mega_tray.get_viewport_rect().size
	assert_gt(rect.position.x, screen.x * 0.6)
	assert_gt(rect.position.y, screen.y * 0.6)
	assert_true(Rect2(Vector2.ZERO, screen).encloses(rect))


func test_at_most_two_full_bursts() -> void:
	var bursts: MegaBursts = add_child_autofree(MegaBursts.new())
	assert_true(bursts.spawn(Vector3.ZERO, 12.0))
	assert_true(bursts.spawn(Vector3(5, 0, 0), 12.0))
	assert_false(bursts.spawn(Vector3(10, 0, 0), 12.0), "cái thứ ba là bản nhẹ")
	assert_eq(bursts.full_count(), 2)
	assert_eq(bursts.active_count(), 3)
	bursts.advance(MegaBursts.DURATION + 0.01)
	assert_eq(bursts.active_count(), 0)
	assert_true(bursts.spawn(Vector3.ZERO, 12.0), "hết vòng cũ thì lại được vòng đầy đủ")
