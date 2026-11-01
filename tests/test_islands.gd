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


func test_docks_are_beside_fortress_and_clear() -> void:
	assert_gte(LAYOUT.satellite_docks.size(), LAYOUT.extra_satellites())
	for a: int in LAYOUT.satellite_docks.size():
		var dock: Vector3 = LAYOUT.satellite_docks[a]
		assert_lt(_flat(dock, LAYOUT.fortress_center), LAYOUT.fortress_radius * 2.4, "chỗ đậu %d xa đảo chính" % a)
		assert_gt(_flat(dock, LAYOUT.fortress_center), LAYOUT.fortress_radius * 1.5)
		for lane: Lane in _lanes:
			assert_gt(lane.distance_to(dock), LAYOUT.satellite_radius + Lane.RIBBON_WIDTH * 0.5 + 2.0, "chỗ đậu %d đè luồng" % a)
		for center: Vector3 in LAYOUT.satellite_centers:
			assert_gte(_flat(dock, center), LAYOUT.satellite_radius * 2.0 + 2.0, "chỗ đậu %d chồng đảo cấp sẵn" % a)
		for b: int in range(a + 1, LAYOUT.satellite_docks.size()):
			assert_gte(_flat(dock, LAYOUT.satellite_docks[b]), LAYOUT.satellite_radius * 2.0 + 2.0)
		for i: int in LAYOUT.pad_count():
			if not LAYOUT.is_satellite_pad(i):
				assert_gt(_flat(dock, LAYOUT.pad_positions[i]), LAYOUT.satellite_radius + AllianceFortress.PIER_END_RADIUS + 1.0)


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


## Một điểm trống trên biển, hợp lệ cho đảo thứ ignore (cách vài chỗ để thử).
func _open_spot(ignore: int) -> Vector3:
	for x: int in range(-80, 81, 4):
		for z: int in range(-80, 41, 4):
			var point: Vector3 = Vector3(x, 0.0, z)
			if LAYOUT.island_spot_valid(point, ignore) and point.length() > 40.0:
				return point
	return Vector3.ZERO


func _tow_until_done(deployer: IslandDeployer, battle: BattleController, k: int) -> void:
	var guard: int = 0
	while deployer.is_towing(k) and guard < 4000:
		deployer.tow_step(0.1)
		guard += 1
	assert_false(deployer.is_towing(k), "đảo phải tới nơi")


func test_spot_validity_rules() -> void:
	assert_false(LAYOUT.island_spot_valid(LAYOUT.fortress_center), "đè đảo chính")
	assert_false(LAYOUT.island_spot_valid(LAYOUT.satellite_centers[0] + Vector3(3, 0, 0)), "chồng đảo cấp sẵn")
	assert_false(LAYOUT.island_spot_valid(LAYOUT.lane_points[1][2]), "đè luồng")
	assert_false(LAYOUT.island_spot_valid(Vector3(400, 0, 0)), "ngoài vùng biển")
	assert_true(LAYOUT.island_spot_valid(_open_spot(-1)))
	assert_true(LAYOUT.island_spot_valid(LAYOUT.satellite_centers[0], 0), "bỏ qua chính đảo đang kéo")


func test_tow_motion_accelerates_cruises_and_brakes() -> void:
	var rules: EconomyData = Profile.economy_rules
	var here: Vector3 = Vector3.ZERO
	var velocity: Vector3 = Vector3.ZERO
	var goal: Vector3 = Vector3(60, 0, 0)
	var first: Dictionary = IslandDeployer.tow_motion(here, velocity, goal, rules.island_tow_speed, rules.island_tow_accel, 0.1)
	assert_lt((first["velocity"] as Vector3).length(), rules.island_tow_speed * 0.2, "khởi hành từ từ, không vọt")
	var top: float = 0.0
	var steps: int = 0
	var arrived: bool = false
	while not arrived and steps < 5000:
		var step: Dictionary = IslandDeployer.tow_motion(here, velocity, goal, rules.island_tow_speed, rules.island_tow_accel, 0.1)
		here = step["position"]
		velocity = step["velocity"]
		arrived = step["arrived"]
		top = maxf(top, velocity.length())
		steps += 1
	assert_true(arrived)
	assert_almost_eq(top, rules.island_tow_speed, 0.01, "chạy đúng tốc độ tối đa")
	assert_gt(float(steps) * 0.1, 60.0 / rules.island_tow_speed, "mất nhiều thời gian hơn đi thẳng tốc độ tối đa vì có tăng tốc và phanh")
	assert_eq(here, goal)


func test_dragged_island_trails_the_finger() -> void:
	Profile.set_gold(100000)
	Profile.buy_island()
	var battle: BattleController = await _new_battle()
	var deployer: IslandDeployer = battle.deployer
	var dock: Vector3 = battle.layout.satellite_centers[4]
	var spot: Vector3 = _open_spot(4)
	assert_true(deployer.begin_drag(battle.camera.unproject_position(dock)))
	deployer.drag_to(battle.camera.unproject_position(spot))
	assert_true(deployer.finger_valid())
	assert_eq(battle.layout.satellite_centers[4], dock, "đảo chưa nhảy tới ngón tay")
	deployer.tow_step(0.5)
	var moved: float = _flat(battle.layout.satellite_centers[4], dock)
	assert_gt(moved, 0.0)
	assert_lt(moved, 1.0, "nửa giây đầu chỉ nhích rất ít")


func test_deploy_island_anywhere_costs_gold_and_unlocks_pad_on_arrival() -> void:
	Profile.set_gold(100000)
	Profile.buy_island()
	var battle: BattleController = await _new_battle()
	var deployer: IslandDeployer = battle.deployer
	var spot: Vector3 = _open_spot(4)
	assert_true(deployer.begin_drag(battle.camera.unproject_position(battle.layout.satellite_centers[4])))
	deployer.drag_to(battle.camera.unproject_position(spot))
	var before: int = battle.economy.steel
	deployer.end_drag()
	assert_eq(battle.economy.steel, before - Profile.island_move_cost())
	assert_true(deployer.is_deployed(4))
	assert_true(battle.island.pads[6 + 4].locked, "đang lai dắt thì bệ chưa mở")
	_tow_until_done(deployer, battle, 4)
	assert_eq(battle.layout.satellite_centers[4], deployer.home_of(4))
	assert_almost_eq(_flat(battle.layout.satellite_centers[4], spot), 0.0, 1.5, "tới chỗ thả, không bị hút vào ô nào")
	assert_eq(battle.layout.pad_positions[6 + 4], battle.layout.satellite_centers[4])
	assert_false(battle.island.pads[6 + 4].locked)
	assert_eq(deployer.docked_count(), 0)


func test_invalid_spot_or_no_gold_tows_island_back_free() -> void:
	Profile.set_gold(100000)
	Profile.buy_island()
	var battle: BattleController = await _new_battle()
	var deployer: IslandDeployer = battle.deployer
	var dock: Vector3 = battle.layout.satellite_centers[4]
	var screen: Vector2 = battle.camera.unproject_position(dock)
	assert_true(deployer.begin_drag(screen))
	deployer.drag_to(battle.camera.unproject_position(battle.layout.fortress_center))
	assert_false(deployer.finger_valid(), "đè đảo chính")
	var before: int = battle.economy.steel
	deployer.end_drag()
	_tow_until_done(deployer, battle, 4)
	assert_eq(battle.layout.satellite_centers[4], dock, "thả chỗ không hợp lệ thì về chỗ đậu")
	assert_eq(battle.economy.steel, before)
	assert_false(deployer.is_deployed(4))
	battle.economy.reset(5)
	assert_true(deployer.begin_drag(screen))
	deployer.drag_to(battle.camera.unproject_position(_open_spot(4)))
	deployer.end_drag()
	_tow_until_done(deployer, battle, 4)
	assert_eq(battle.layout.satellite_centers[4], dock, "thiếu vàng thì về chỗ đậu")
	assert_eq(battle.economy.steel, 5)
	assert_true(battle.island.pads[6 + 4].locked)


func test_free_islands_cannot_be_dragged() -> void:
	var battle: BattleController = await _new_battle()
	var screen: Vector2 = battle.camera.unproject_position(battle.layout.satellite_centers[0])
	assert_false(battle.deployer.begin_drag(screen), "đảo cấp sẵn cố định")


func test_island_with_tower_cannot_be_moved_and_retry_returns_islands() -> void:
	Profile.set_gold(100000)
	Profile.buy_island()
	var battle: BattleController = await _new_battle()
	var deployer: IslandDeployer = battle.deployer
	var screen: Vector2 = battle.camera.unproject_position(battle.layout.satellite_centers[4])
	deployer.begin_drag(screen)
	deployer.drag_to(battle.camera.unproject_position(_open_spot(4)))
	deployer.end_drag()
	_tow_until_done(deployer, battle, 4)
	var pad: TowerPad = battle.island.pads[6 + 4]
	battle.economy.reset(1000)
	var tower: Tower = battle.build_tower(pad, load("res://data/towers/machine_gun.tres"))
	assert_not_null(tower)
	var now: Vector2 = battle.camera.unproject_position(battle.layout.satellite_centers[4])
	assert_false(deployer.begin_drag(now), "đảo đã có lô cốt thì không kéo được")
	battle.retry()
	assert_eq(battle.layout.satellite_centers[4], LAYOUT.satellite_docks[0], "chơi lại thì đảo về chỗ đậu")


func test_changing_lighting_keeps_pads_and_towers() -> void:
	var battle: BattleController = await _new_battle()
	var pads: Array[TowerPad] = battle.island.pads.duplicate()
	for id: StringName in Lighting.ORDER:
		battle.set_lighting(id)
	for weather_id: StringName in [&"rain", &"storm", &"clear"]:
		battle.set_weather(weather_id)
	assert_eq(battle.island.pads.size(), pads.size())
	for i: int in pads.size():
		assert_same(battle.island.pads[i], pads[i], "đổi ánh sáng không dựng lại đảo")


func test_free_islands_follow_each_levels_own_arrangement() -> void:
	var other: MapLayout = LAYOUT.duplicate() as MapLayout
	var shifted: PackedVector3Array = PackedVector3Array()
	for center: Vector3 in LAYOUT.satellite_centers:
		shifted.append(center.rotated(Vector3.UP, 0.5))
	other.satellite_centers = shifted
	var layout: MapLayout = Profile.battle_layout(other)
	for i: int in LAYOUT.satellite_centers.size():
		assert_eq(layout.satellite_centers[i], shifted[i], "đảo cấp sẵn %d theo bố cục của màn" % i)
		assert_ne(layout.satellite_centers[i], LAYOUT.satellite_centers[i])
