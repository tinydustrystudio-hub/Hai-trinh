extends GutTest
## Đảo vệ tinh (P5c, sửa 1/11): đảo mua có mãi và đậu cạnh đảo chính; vào trận kéo ra ô, tốn phí kéo trừ vàng trong trận.
## Đảo cấp sẵn cố định ở ô mặc định.

const LAYOUT: MapLayout = preload("res://data/maps/north_dock_layout.tres")
const TEMP_PATH: String = "user://test_islands.cfg"

var _lanes: Array[Lane] = []


func before_all() -> void:
	for i: int in LAYOUT.lane_count():
		var lane: Lane = Lane.new()
		lane.setup(i, LAYOUT.lane_points[i], LAYOUT.lane_name_keys[i])
		_lanes.append(lane)


func after_all() -> void:
	for lane: Lane in _lanes:
		lane.free()
	_lanes.clear()
	Profile.reset_to_new()
	DirAccess.remove_absolute(TEMP_PATH)


func before_each() -> void:
	Profile.reset_to_new()


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _new_battle() -> BattleController:
	var battle: BattleController = load("res://battle/battle.tscn").instantiate()
	add_child_autofree(battle)
	await get_tree().process_frame
	return battle


func test_slots_start_with_default_centers() -> void:
	assert_gte(LAYOUT.slot_count(), LAYOUT.satellite_max_count)
	for i: int in LAYOUT.satellite_centers.size():
		assert_eq(LAYOUT.satellite_slots[i], LAYOUT.satellite_centers[i])


func test_every_slot_is_clear_of_lanes_and_reaches_one() -> void:
	var reach: float = 2.5 * TowerData.RANGE_BONUS * MapLayout.UNITS_PER_CELL
	for slot: int in LAYOUT.slot_count():
		var nearest: float = INF
		for lane: Lane in _lanes:
			nearest = minf(nearest, lane.distance_to(LAYOUT.satellite_slots[slot]))
		assert_gt(nearest, LAYOUT.satellite_radius + Lane.RIBBON_WIDTH * 0.5, "ô %d đè luồng" % slot)
		assert_lte(nearest, reach, "ô %d không với tới luồng" % slot)


func test_docks_are_beside_fortress_and_clear() -> void:
	assert_gte(LAYOUT.satellite_docks.size(), LAYOUT.extra_satellites())
	for a: int in LAYOUT.satellite_docks.size():
		var dock: Vector3 = LAYOUT.satellite_docks[a]
		assert_lt(_flat(dock, LAYOUT.fortress_center), LAYOUT.fortress_radius * 2.4, "chỗ đậu %d xa đảo chính" % a)
		assert_gt(_flat(dock, LAYOUT.fortress_center), LAYOUT.fortress_radius * 1.5)
		for lane: Lane in _lanes:
			assert_gt(lane.distance_to(dock), LAYOUT.satellite_radius + Lane.RIBBON_WIDTH * 0.5 + 2.0, "chỗ đậu %d đè luồng" % a)
		for slot: int in LAYOUT.slot_count():
			assert_gte(_flat(dock, LAYOUT.satellite_slots[slot]), LAYOUT.satellite_radius * 2.0 + 2.0, "chỗ đậu %d chồng ô %d" % [a, slot])
		for b: int in range(a + 1, LAYOUT.satellite_docks.size()):
			assert_gte(_flat(dock, LAYOUT.satellite_docks[b]), LAYOUT.satellite_radius * 2.0 + 2.0)
		for i: int in LAYOUT.pad_count():
			if not LAYOUT.is_satellite_pad(i):
				assert_gt(_flat(dock, LAYOUT.pad_positions[i]), LAYOUT.satellite_radius + AllianceFortress.PIER_END_RADIUS + 1.0)


func test_slots_do_not_overlap_each_other_or_fortress() -> void:
	for a: int in LAYOUT.slot_count():
		assert_gt(_flat(LAYOUT.satellite_slots[a], LAYOUT.fortress_center), LAYOUT.fortress_radius * 2.0, "ô %d sát đảo chính" % a)
		for b: int in range(a + 1, LAYOUT.slot_count()):
			assert_gte(_flat(LAYOUT.satellite_slots[a], LAYOUT.satellite_slots[b]), LAYOUT.satellite_radius * 2.0 + 2.0, "ô %d và %d chồng nhau" % [a, b])


func test_new_player_has_four_free_islands_and_no_purchase() -> void:
	assert_eq(Profile.island_total(), 4)
	assert_eq(Profile.bought_islands, 0)


func test_buy_island_costs_and_stays_docked() -> void:
	Profile.set_gold(1000)
	assert_eq(Profile.island_buy_cost(), 250)
	assert_true(Profile.buy_island())
	assert_eq(Profile.gold, 750)
	assert_eq(Profile.island_total(), 5)
	assert_eq(Profile.island_buy_cost(), 300, "mỗi đảo sau +50")
	var layout: MapLayout = Profile.battle_layout(LAYOUT)
	assert_eq(layout.satellite_centers.size(), 5)
	assert_eq(layout.satellite_centers[4], LAYOUT.satellite_docks[0], "đảo mua đậu ở chỗ đậu")
	assert_eq(layout.pad_count(), 6 + 5)


func test_cannot_buy_without_gold_or_beyond_max() -> void:
	Profile.set_gold(100)
	assert_false(Profile.buy_island())
	Profile.set_gold(100000)
	for i: int in 10:
		Profile.buy_island()
	assert_eq(Profile.bought_islands, Profile.max_bought_islands())
	assert_eq(Profile.island_total(), LAYOUT.satellite_max_count)


func test_deploy_cost_is_half_cheapest_tower() -> void:
	assert_eq(Profile.island_move_cost(), Profile.cheapest_tower_cost() / 2)


func test_save_and_load_bought_islands() -> void:
	Profile.set_gold(100000)
	Profile.buy_island()
	Profile.buy_island()
	assert_true(Profile.save(TEMP_PATH, true))
	Profile.reset_to_new()
	assert_eq(Profile.bought_islands, 0)
	assert_true(Profile.load_saved(TEMP_PATH))
	assert_eq(Profile.bought_islands, 2)


func test_load_ignores_bad_island_data() -> void:
	Profile.apply_dictionary({"gold": 10, "bought": 99})
	assert_eq(Profile.bought_islands, Profile.max_bought_islands())
	Profile.apply_dictionary({"gold": 10, "bought": "x"})
	assert_eq(Profile.bought_islands, 0)


func test_battle_starts_with_bought_islands_docked_and_locked() -> void:
	Profile.set_gold(100000)
	Profile.buy_island()
	var battle: BattleController = await _new_battle()
	assert_eq(battle.island.satellites.size(), 5)
	assert_eq(battle.deployer.docked_count(), 1)
	assert_eq(battle.layout.satellite_centers[4], LAYOUT.satellite_docks[0])
	var pad: TowerPad = battle.island.pads[6 + 4]
	assert_true(pad.locked)
	assert_false(pad.is_selectable())
	assert_null(battle.island.pad_near(pad.global_position, 3.0), "bệ khoá không chọn được")


func test_deploy_island_to_slot_costs_gold_and_unlocks_pad() -> void:
	Profile.set_gold(100000)
	Profile.buy_island()
	var battle: BattleController = await _new_battle()
	var deployer: IslandDeployer = battle.deployer
	var screen: Vector2 = battle.camera.unproject_position(battle.layout.satellite_centers[4])
	assert_true(deployer.begin_drag(screen))
	var slot: int = 6
	assert_true(deployer.slot_is_free(slot))
	var target: Vector2 = battle.camera.unproject_position(deployer.slot_position(slot))
	deployer.drag_to(target)
	var before: int = battle.economy.steel
	deployer.end_drag()
	assert_eq(battle.economy.steel, before - Profile.island_move_cost())
	assert_true(deployer.is_deployed(4))
	assert_eq(deployer.slot_of(4), slot)
	assert_eq(battle.layout.satellite_centers[4], deployer.slot_position(slot))
	assert_eq(battle.layout.pad_positions[6 + 4], deployer.slot_position(slot))
	assert_false(battle.island.pads[6 + 4].locked)
	assert_false(deployer.slot_is_free(slot), "ô đã có đảo")
	assert_eq(deployer.docked_count(), 0)


func test_drop_outside_slot_or_without_gold_returns_island() -> void:
	Profile.set_gold(100000)
	Profile.buy_island()
	var battle: BattleController = await _new_battle()
	var deployer: IslandDeployer = battle.deployer
	var dock: Vector3 = battle.layout.satellite_centers[4]
	var screen: Vector2 = battle.camera.unproject_position(dock)
	assert_true(deployer.begin_drag(screen))
	deployer.drag_to(Vector2(30, 30))
	var before: int = battle.economy.steel
	deployer.end_drag()
	assert_eq(battle.layout.satellite_centers[4], dock, "thả ngoài ô thì về chỗ đậu")
	assert_eq(battle.economy.steel, before)
	assert_false(deployer.is_deployed(4))
	battle.economy.reset(5)
	assert_true(deployer.begin_drag(screen))
	deployer.drag_to(battle.camera.unproject_position(deployer.slot_position(6)))
	deployer.end_drag()
	assert_eq(battle.layout.satellite_centers[4], dock, "thiếu vàng thì về chỗ đậu")
	assert_eq(battle.economy.steel, 5)
	assert_true(battle.island.pads[6 + 4].locked)


func test_free_islands_cannot_be_dragged_and_default_slots_not_free() -> void:
	var battle: BattleController = await _new_battle()
	var deployer: IslandDeployer = battle.deployer
	for slot: int in 4:
		assert_false(deployer.slot_is_free(slot), "ô mặc định của đảo cấp sẵn")
	var screen: Vector2 = battle.camera.unproject_position(battle.layout.satellite_centers[0])
	assert_false(deployer.begin_drag(screen), "đảo cấp sẵn cố định")


func test_island_with_tower_cannot_be_moved_and_retry_returns_islands() -> void:
	Profile.set_gold(100000)
	Profile.buy_island()
	var battle: BattleController = await _new_battle()
	var deployer: IslandDeployer = battle.deployer
	var screen: Vector2 = battle.camera.unproject_position(battle.layout.satellite_centers[4])
	deployer.begin_drag(screen)
	deployer.drag_to(battle.camera.unproject_position(deployer.slot_position(6)))
	deployer.end_drag()
	var pad: TowerPad = battle.island.pads[6 + 4]
	battle.economy.reset(1000)
	var tower: Tower = battle.build_tower(pad, load("res://data/towers/machine_gun.tres"))
	assert_not_null(tower)
	var now: Vector2 = battle.camera.unproject_position(battle.layout.satellite_centers[4])
	assert_false(deployer.begin_drag(now), "đảo đã có lô cốt thì không kéo được")
	battle.retry()
	assert_eq(battle.layout.satellite_centers[4], LAYOUT.satellite_docks[0], "chơi lại thì đảo về chỗ đậu")
	assert_eq(deployer.docked_count(), 1)


func test_island_panel_and_base_screen_show_docked_islands() -> void:
	TranslationServer.set_locale("vi")
	var screen: BaseScreen = BaseScreen.new()
	add_child_autofree(screen)
	await wait_process_frames(2)
	screen.tab_islands_button().pressed.emit()
	var panel: IslandPanel = screen.island_panel()
	assert_true(panel.visible)
	assert_eq(panel.count_text(), "Đảo sở hữu: 4 (đã mua thêm 0/4)")
	assert_eq(panel.move_text(), "Phí kéo một đảo ra trong trận: %d" % Profile.island_move_cost())
	Profile.set_gold(1000)
	panel.buy_button().pressed.emit()
	assert_eq(Profile.bought_islands, 1)
	assert_eq(screen.island().satellites.size(), 5, "đảo mua hiện cạnh đảo chính")
	panel.reset_button().pressed.emit()
	assert_eq(Profile.bought_islands, 0)
	assert_eq(screen.island().satellites.size(), 4)
	screen.tab_buildings_button().pressed.emit()
	assert_true(screen.upgrade_button(&"shipyard").visible)
