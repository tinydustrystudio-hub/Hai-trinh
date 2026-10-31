extends GutTest
## Chạm bệ → vòng chọn → đặt Súng Máy; Thép trừ đúng; vòng chọn xám khi thiếu Thép; Súng Máy hạ được Xuồng Cướp.

const BATTLE_SCENE: PackedScene = preload("res://battle/battle.tscn")
const MG: TowerData = preload("res://data/towers/machine_gun.tres")
const STEP: float = 0.1

var _battle: BattleController


func before_each() -> void:
	TranslationServer.set_locale("vi")
	_battle = add_child_autofree(BATTLE_SCENE.instantiate())


func test_starting_steel_on_hud() -> void:
	assert_eq(_battle.economy.steel, 200)
	assert_eq(_battle.hud.steel_text(), "Thép: 200")


func test_build_spends_steel_and_occupies_pad() -> void:
	var pad: TowerPad = _battle.island.pads[4]
	var tower: Tower = _battle.build_tower(pad, MG)
	assert_not_null(tower)
	assert_true(tower is MachineGun)
	assert_true(pad.occupied)
	assert_eq(_battle.economy.steel, 130)
	assert_eq(tower.invested, 70)
	assert_eq(_battle.hud.steel_text(), "Thép: 130")
	assert_null(_battle.build_tower(pad, MG), "bệ đã có lô cốt")
	assert_eq(_battle.economy.steel, 130)


func test_cannot_build_without_steel() -> void:
	_battle.economy.reset(69)
	assert_null(_battle.build_tower(_battle.island.pads[0], MG))
	assert_false(_battle.island.pads[0].occupied)
	assert_eq(_battle.economy.steel, 69)


func test_build_ring_greys_out_when_short() -> void:
	var ring: BuildRing = _battle.hud.build_ring
	ring.open(Vector2(900, 500), _battle.tower_choices, 200)
	assert_true(ring.is_open())
	# Súng Máy (70) và Lô Cốt Keo (60).
	assert_eq(ring.buttons().size(), 2)
	assert_false(ring.buttons()[0].disabled)
	assert_string_contains(ring.buttons()[0].text, "70")
	assert_string_contains(ring.buttons()[1].text, "60")
	ring.set_steel(65)
	assert_true(ring.buttons()[0].disabled)
	assert_false(ring.buttons()[1].disabled)
	ring.set_steel(50)
	assert_true(ring.buttons()[1].disabled)
	ring.set_steel(70)
	assert_false(ring.buttons()[0].disabled)


func test_ring_choice_builds_on_selected_pad() -> void:
	var pad: TowerPad = _battle.island.pads[2]
	_battle.select_pad(pad)
	_battle.hud.build_ring.open(Vector2(900, 500), _battle.tower_choices, _battle.economy.steel)
	_battle.hud.build_ring.buttons()[0].pressed.emit()
	assert_true(pad.occupied)
	assert_false(_battle.hud.build_ring.is_open())
	assert_null(_battle.selected_pad)
	assert_eq(_battle.economy.steel, 130)


func test_ring_buttons_are_big_and_on_screen() -> void:
	var screen: Vector2 = Vector2(1920, 1080)
	assert_gte(BuildRing.BUTTON_SIZE, 120.0)
	for at: Vector2 in [Vector2(960, 540), Vector2(10, 10), Vector2(1910, 1070)]:
		var centers: Array[Vector2] = []
		for i: int in 2:
			var center: Vector2 = BuildRing.button_center(i, 2, at, screen)
			assert_true(Rect2(Vector2.ZERO, screen).has_point(center - Vector2.ONE * BuildRing.BUTTON_SIZE * 0.5))
			assert_true(Rect2(Vector2.ZERO, screen).has_point(center + Vector2.ONE * BuildRing.BUTTON_SIZE * 0.5))
			centers.append(center)
		if at == Vector2(960, 540):
			# Hai nút không chồng nhau và cách nhau ít nhất 8 px (GDD mục 7.1).
			assert_gte(centers[0].distance_to(centers[1]), BuildRing.BUTTON_SIZE + 8.0)


func test_wave_bonus_and_kill_rewards() -> void:
	# Súng Máy trên mỏm bến phía Bắc, cạnh luồng Bắc của đợt 1.
	_battle.build_tower(_battle.island.pads[4], MG)
	var kills: Array[int] = [0]
	var count_kill: Callable = func(_e: Enemy, _r: int) -> void: kills[0] += 1
	Events.enemy_killed.connect(count_kill)
	# Chạy tới khi đợt 1 xong (bộ sinh đợt chuyển sang chờ đợt 2).
	var elapsed: float = 0.0
	while _battle.spawner.wave_index == 0 and elapsed < 120.0:
		_battle.step(STEP)
		elapsed += STEP
	Events.enemy_killed.disconnect(count_kill)
	assert_gt(kills[0], 0, "Súng Máy phải hạ được Xuồng Cướp")
	# 200 − 70 + 20 (đầu đợt 1) + 5 mỗi con bị hạ.
	assert_eq(_battle.economy.steel, 200 - 70 + 20 + 5 * kills[0])


func test_retry_removes_towers_and_resets_steel() -> void:
	var pad: TowerPad = _battle.island.pads[0]
	_battle.build_tower(pad, MG)
	_battle.retry()
	assert_false(pad.occupied)
	assert_eq(_battle.towers.size(), 0)
	assert_eq(_battle.economy.steel, 200)
