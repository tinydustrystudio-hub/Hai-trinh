extends GutTest
## Cảnh thử hiệu năng và bảng debug: luôn giữ đủ 60 địch, không vượt trần, cờ khởi chạy đọc đúng.

const BATTLE_SCENE: PackedScene = preload("res://battle/battle.tscn")
const STRESS_SCENE: PackedScene = preload("res://test_scenes/stress_test.tscn")


func test_query_flags() -> void:
	assert_true(Settings.has_query_flag("?debug", "debug"))
	assert_true(Settings.has_query_flag("?a=1&stress", "stress"))
	assert_true(Settings.has_query_flag("?stress=1", "stress"))
	assert_false(Settings.has_query_flag("?stressed", "stress"))
	assert_false(Settings.has_query_flag("", "debug"))


func test_stress_scene_keeps_sixty_enemies() -> void:
	var scene: Node3D = add_child_autofree(STRESS_SCENE.instantiate())
	var battle: BattleController = scene.get_node("Battle")
	assert_true(battle.stress_mode)
	assert_eq(battle.enemy_pool.active_count(), 60)
	for i: int in 600:
		battle.step(0.1)
		assert_eq(battle.enemy_pool.active_count(), 60)
	assert_false(battle.is_over(), "cảnh thử không bao giờ kết thúc")


func test_burst_respects_cap() -> void:
	var battle: BattleController = add_child_autofree(BATTLE_SCENE.instantiate())
	assert_eq(battle.spawn_burst(60), 60)
	assert_eq(battle.spawn_burst(10), 0)
	assert_eq(battle.enemy_pool.active_count(), BattleController.MAX_ACTIVE_ENEMIES)


func test_burst_enemies_do_not_count_for_wave() -> void:
	var battle: BattleController = add_child_autofree(BATTLE_SCENE.instantiate())
	battle.spawn_burst(5)
	for enemy: Enemy in battle.enemy_pool.active:
		assert_false(enemy.counts_for_wave)
	# Hạ hết địch sinh từ bảng debug: bộ đếm của đợt không được âm hay lệch.
	for i: int in range(battle.enemy_pool.active.size() - 1, -1, -1):
		battle.enemy_pool.damage(battle.enemy_pool.active[i], 100000.0)
	assert_eq(battle.spawner.alive, 0)


func test_enemy_types_from_waves() -> void:
	var data: WaveData = load("res://data/waves/north_dock_waves.tres")
	var types: Array[EnemyData] = BattleController.enemy_types_in(data)
	assert_eq(types.size(), 3)


func test_debug_overlay_in_debug_build() -> void:
	var battle: BattleController = add_child_autofree(BATTLE_SCENE.instantiate())
	await wait_process_frames(1)
	var overlay: DebugOverlay = battle.get_node_or_null("DebugOverlay")
	assert_not_null(overlay, "bản debug phải có bảng debug")
	var s: Dictionary = overlay.snapshot()
	assert_eq(s["enemies"], 0)
	var line: String = DebugOverlay.perf_line(s)
	assert_true(line.begins_with("PERF fps="))
	assert_string_contains(line, "enemies=0")
