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
			if LAYOUT.is_pier_pad(i):
				assert_gt(_flat(dock, LAYOUT.pad_positions[i]), LAYOUT.satellite_radius + AllianceFortress.PIER_END_RADIUS + 1.0)


func test_buy_island_costs_and_stays_docked() -> void:
	Profile.set_gold(1000)
	assert_eq(Profile.island_buy_cost(), 250)
	assert_true(Profile.buy_island())
	assert_eq(Profile.gold, 750)
	assert_eq(Profile.island_total(), 1, "không có đảo cấp sẵn: tổng = số đảo đã mua")
	assert_eq(Profile.island_buy_cost(), 300, "mỗi đảo sau +50")
	var layout: MapLayout = Profile.battle_layout(LAYOUT)
	assert_eq(layout.satellite_centers.size(), 1)
	assert_eq(layout.satellite_centers[0], LAYOUT.satellite_docks[0], "đảo mua đậu ở chỗ đậu")
	assert_eq(layout.pad_count(), 6 + LAYOUT.platform_centers.size() + 1)


func test_cannot_buy_without_gold_or_beyond_max() -> void:
	Profile.set_gold(100)
	assert_false(Profile.buy_island())
	Profile.set_gold(100000)
	for i: int in 10:
		Profile.buy_island()
	assert_eq(Profile.bought_islands, Profile.max_bought_islands())
	assert_eq(Profile.island_total(), LAYOUT.free_satellites() + LAYOUT.extra_satellites(Profile.difficulty))
	assert_lte(Profile.island_total(), LAYOUT.satellite_max_count)


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
	assert_eq(battle.island.satellites.size(), 1)
	assert_eq(battle.deployer.docked_count(), 1)
	assert_eq(battle.layout.satellite_centers[0], LAYOUT.satellite_docks[0])
	var pad: TowerPad = battle.island.pads[battle.island.pads.size() - 1]
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
	var others: MapLayout = TestLayouts.with_satellites(2)
	assert_false(others.island_spot_valid(others.satellite_centers[0] + Vector3(3, 0, 0)), "chồng đảo khác")
	assert_false(LAYOUT.island_spot_valid(LAYOUT.lane_points[1][2]), "đè luồng")
	assert_false(LAYOUT.island_spot_valid(Vector3(400, 0, 0)), "ngoài vùng biển")
	assert_true(LAYOUT.island_spot_valid(_open_spot(-1)))
	assert_true(others.island_spot_valid(others.satellite_centers[0], 0), "bỏ qua chính đảo đang kéo")


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
	var dock: Vector3 = battle.layout.satellite_centers[0]
	var spot: Vector3 = _open_spot(0)
	assert_true(deployer.begin_drag(battle.camera.unproject_position(dock)))
	deployer.drag_to(battle.camera.unproject_position(spot))
	assert_true(deployer.finger_valid())
	assert_eq(battle.layout.satellite_centers[0], dock, "đảo chưa nhảy tới ngón tay")
	deployer.tow_step(0.5)
	var moved: float = _flat(battle.layout.satellite_centers[0], dock)
	assert_gt(moved, 0.0)
	assert_lt(moved, 1.0, "nửa giây đầu chỉ nhích rất ít")


func test_deploy_island_anywhere_costs_gold_and_unlocks_pad_on_arrival() -> void:
	Profile.set_gold(100000)
	Profile.buy_island()
	var battle: BattleController = await _new_battle()
	var deployer: IslandDeployer = battle.deployer
	var spot: Vector3 = _open_spot(0)
	assert_true(deployer.begin_drag(battle.camera.unproject_position(battle.layout.satellite_centers[0])))
	deployer.drag_to(battle.camera.unproject_position(spot))
	var before: int = battle.economy.steel
	deployer.end_drag()
	assert_eq(deployer.pending_island(), 0, "thả ở chỗ hợp lệ thì chờ xác nhận")
	assert_eq(battle.economy.steel, before, "chưa xác nhận thì chưa tốn vàng")
	assert_false(deployer.is_deployed(0))
	assert_true(deployer.confirm())
	assert_eq(battle.economy.steel, before - Profile.island_move_cost())
	assert_true(deployer.is_deployed(0))
	assert_eq(deployer.pending_island(), -1)
	assert_true(battle.island.pads[battle.island.pads.size() - 1].locked, "đang lai dắt thì bệ chưa mở")
	_tow_until_done(deployer, battle, 0)
	assert_eq(battle.layout.satellite_centers[0], deployer.home_of(0))
	assert_almost_eq(_flat(battle.layout.satellite_centers[0], spot), 0.0, 1.5, "tới chỗ thả, không bị hút vào ô nào")
	assert_eq(battle.layout.pad_positions[battle.layout.pad_count() - 1], battle.layout.satellite_centers[0])
	assert_false(battle.island.pads[battle.island.pads.size() - 1].locked)
	assert_eq(deployer.docked_count(), 0)


func test_invalid_spot_or_no_gold_tows_island_back_free() -> void:
	Profile.set_gold(100000)
	Profile.buy_island()
	var battle: BattleController = await _new_battle()
	var deployer: IslandDeployer = battle.deployer
	var dock: Vector3 = battle.layout.satellite_centers[0]
	var screen: Vector2 = battle.camera.unproject_position(dock)
	assert_true(deployer.begin_drag(screen))
	deployer.drag_to(battle.camera.unproject_position(battle.layout.fortress_center))
	assert_false(deployer.finger_valid(), "đè đảo chính")
	var before: int = battle.economy.steel
	deployer.end_drag()
	assert_eq(deployer.pending_island(), -1, "chỗ không hợp lệ thì không hỏi xác nhận")
	_tow_until_done(deployer, battle, 0)
	assert_eq(battle.layout.satellite_centers[0], dock, "thả chỗ không hợp lệ thì về chỗ đậu")
	assert_eq(battle.economy.steel, before)
	assert_false(deployer.is_deployed(0))
	assert_true(deployer.begin_drag(screen))
	deployer.drag_to(battle.camera.unproject_position(_open_spot(0)))
	deployer.end_drag()
	battle.economy.reset(5)
	assert_false(deployer.confirm(), "thiếu vàng thì không xác nhận được")
	assert_eq(deployer.pending_island(), 0)
	deployer.decline()
	_tow_until_done(deployer, battle, 0)
	assert_eq(battle.layout.satellite_centers[0], dock, "huỷ thì về chỗ đậu")
	assert_eq(battle.economy.steel, 5)
	assert_true(battle.island.pads[battle.island.pads.size() - 1].locked)


func test_no_free_islands_and_empty_water_is_not_draggable() -> void:
	var battle: BattleController = await _new_battle()
	assert_eq(battle.island.satellites.size(), 0, "vào màn không có đảo phụ cấp sẵn")
	assert_eq(battle.deployer.bought_count(), 0)
	assert_false(battle.deployer.begin_drag(Vector2(960, 540)))


func test_island_with_tower_moves_with_it_and_costs_both_fees() -> void:
	Profile.set_gold(100000)
	Profile.buy_island()
	var battle: BattleController = await _new_battle()
	var deployer: IslandDeployer = battle.deployer
	var screen: Vector2 = battle.camera.unproject_position(battle.layout.satellite_centers[0])
	deployer.begin_drag(screen)
	deployer.drag_to(battle.camera.unproject_position(_open_spot(0)))
	deployer.end_drag()
	deployer.confirm()
	_tow_until_done(deployer, battle, 0)
	var pad: TowerPad = battle.island.pads[battle.island.pads.size() - 1]
	battle.economy.reset(1000)
	var tower: Tower = battle.build_tower(pad, load("res://data/towers/machine_gun.tres"))
	assert_not_null(tower)
	assert_eq(deployer.move_cost(0), Profile.island_move_cost() + Profile.tower_move_cost(), "đảo có lô cốt: phí đảo + phí lô cốt")
	var before: int = battle.economy.steel
	var now: Vector2 = battle.camera.unproject_position(battle.layout.satellite_centers[0])
	assert_true(deployer.begin_drag(now), "đảo đã có lô cốt vẫn kéo được")
	var spot: Vector3 = _open_spot_far_from(battle.layout.satellite_centers[0], 0)
	deployer.drag_to(battle.camera.unproject_position(spot))
	deployer.end_drag()
	assert_true(deployer.confirm())
	assert_eq(battle.economy.steel, before - deployer.move_cost(0))
	_tow_until_done(deployer, battle, 0)
	await get_tree().process_frame
	assert_eq(tower.pad, pad, "lô cốt vẫn ở bệ của đảo")
	assert_almost_eq(tower.global_position.x, battle.layout.satellite_centers[0].x, 1.0, "lô cốt đi theo đảo")
	battle.retry()
	assert_eq(battle.layout.satellite_centers[0], LAYOUT.satellite_docks[0], "chơi lại thì đảo về chỗ đậu")


func _open_spot_far_from(origin: Vector3, ignore: int) -> Vector3:
	var best: Vector3 = Vector3.ZERO
	var best_distance: float = 0.0
	for x: int in range(-80, 81, 4):
		for z: int in range(-80, 41, 4):
			var point: Vector3 = Vector3(x, 0.0, z)
			if LAYOUT.island_spot_valid(point, ignore) and _flat(point, origin) > best_distance and _flat(point, origin) < 40.0:
				best = point
				best_distance = _flat(point, origin)
	return best


func test_island_cannot_be_lifted_without_gold() -> void:
	Profile.set_gold(100000)
	Profile.buy_island()
	var battle: BattleController = await _new_battle()
	var deployer: IslandDeployer = battle.deployer
	battle.economy.reset(Profile.island_move_cost() - 1)
	var screen: Vector2 = battle.camera.unproject_position(battle.layout.satellite_centers[0])
	assert_true(deployer.begin_drag(screen), "cử chỉ được xử lý (không kéo camera)")
	assert_false(deployer.is_dragging(), "nhưng đảo không rời chỗ")
	assert_eq(battle.economy.steel, Profile.island_move_cost() - 1)


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


func test_docks_follow_each_levels_own_arrangement() -> void:
	var other: MapLayout = LAYOUT.duplicate() as MapLayout
	var shifted: PackedVector3Array = PackedVector3Array()
	for dock: Vector3 in LAYOUT.satellite_docks:
		shifted.append(dock.rotated(Vector3.UP, 0.5))
	other.satellite_docks = shifted
	Profile.set_gold(100000)
	Profile.buy_island()
	var layout: MapLayout = Profile.battle_layout(other)
	assert_eq(layout.satellite_centers[0], shifted[0], "chỗ đậu theo bố cục của màn")
	assert_ne(layout.satellite_centers[0], LAYOUT.satellite_docks[0])


func test_waypoint_goes_around_an_island_in_the_way() -> void:
	var obstacles: Array[Vector4] = [Vector4(20, 0, 5, 0)]
	var here: Vector3 = Vector3.ZERO
	var goal: Vector3 = Vector3(40, 0, 0)
	var way: Vector3 = IslandDeployer.next_waypoint(here, goal, obstacles)
	assert_ne(way, goal, "đường thẳng bị chắn thì phải vòng")
	assert_gt(absf(way.z), 5.0, "điểm vòng nằm ngoài mép vật cản")
	assert_eq(IslandDeployer.next_waypoint(here, Vector3(0, 0, 40), obstacles), Vector3(0, 0, 40), "đường thoáng thì đi thẳng")


func test_towed_island_never_enters_another_island() -> void:
	Profile.set_gold(100000)
	Profile.buy_island()
	var battle: BattleController = await _new_battle()
	var deployer: IslandDeployer = battle.deployer
	var layout: MapLayout = battle.layout
	var screen: Vector2 = battle.camera.unproject_position(layout.satellite_centers[0])
	assert_true(deployer.begin_drag(screen))
	# Đích ở phía bên kia đảo chính so với chỗ đậu: đường thẳng phải xuyên qua đảo chính.
	var spot: Vector3 = Vector3.ZERO
	for x: int in range(-80, 81, 4):
		for z: int in range(-80, 41, 4):
			var point: Vector3 = Vector3(x, 0.0, z)
			if spot == Vector3.ZERO and layout.island_spot_valid(point, 0) and _flat(point, layout.satellite_centers[0]) > 45.0 and point.z * layout.satellite_centers[0].z < 0.0:
				spot = point
	assert_ne(spot, Vector3.ZERO)
	deployer.drag_to(battle.camera.unproject_position(spot))
	var closest: float = INF
	var guard: int = 0
	while deployer.is_towing(0) and guard < 4000:
		deployer.tow_step(0.1)
		guard += 1
		closest = minf(closest, _flat(layout.satellite_centers[0], layout.fortress_center))
		for j: int in range(1, layout.satellite_centers.size()):
			assert_gt(_flat(layout.satellite_centers[0], layout.satellite_centers[j]), layout.satellite_radius * 2.0, "xuyên đảo %d" % j)
	assert_gt(closest, layout.fortress_radius + layout.satellite_radius, "không xuyên đảo chính")
	assert_lt(_flat(layout.satellite_centers[0], spot), 1.5, "vẫn tới được đích")


func test_grid_marks_reachable_blue_and_blocked_red() -> void:
	var mesh: ArrayMesh = IslandDeployer.build_grid(LAYOUT, -1)
	var colors: PackedColorArray = mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var blue: int = 0
	var red: int = 0
	for c: Color in colors:
		if c.b > c.r:
			blue += 1
		else:
			red += 1
	assert_gt(blue, 0)
	assert_gt(red, 0)
	assert_lt(colors.size() / 6, 3000, "ngân sách số ô lưới")


func test_grid_shows_only_while_dragging_or_pending() -> void:
	Profile.set_gold(100000)
	Profile.buy_island()
	var battle: BattleController = await _new_battle()
	var deployer: IslandDeployer = battle.deployer
	var grid: MeshInstance3D = battle.island.get_node("IslandGrid") as MeshInstance3D
	assert_false(grid.visible)
	deployer.begin_drag(battle.camera.unproject_position(battle.layout.satellite_centers[0]))
	assert_true(grid.visible)
	deployer.drag_to(battle.camera.unproject_position(_open_spot(0)))
	deployer.end_drag()
	assert_true(grid.visible, "chờ xác nhận vẫn hiện lưới")
	deployer.decline()
	assert_false(grid.visible)


## Kéo đảo tới nhiều đích khắp biển (kể cả đích xuyên qua đảo khác): trên mọi bước đảo không được chồng lên đảo nào.
func test_tow_sweep_never_overlaps_any_island() -> void:
	Profile.set_gold(100000)
	Profile.buy_island()
	var battle: BattleController = await _new_battle()
	var deployer: IslandDeployer = battle.deployer
	var layout: MapLayout = battle.layout
	var reach: float = layout.fortress_radius
	for i: int in layout.pad_count():
		if layout.is_pier_pad(i):
			reach = maxf(reach, _flat(layout.pad_positions[i], layout.fortress_center) + AllianceFortress.PIER_END_RADIUS)
	var targets: Array[Vector3] = []
	for x: int in range(-80, 81, 20):
		for z: int in range(-80, 41, 20):
			var point: Vector3 = Vector3(x, 0.0, z)
			if layout.island_spot_valid(point, 0):
				targets.append(point)
	assert_gt(targets.size(), 8)
	var worst_island: float = INF
	var worst_fortress: float = INF
	for target: Vector3 in targets:
		var screen: Vector2 = battle.camera.unproject_position(layout.satellite_centers[0])
		assert_true(deployer.begin_drag(screen))
		deployer.drag_to(battle.camera.unproject_position(target))
		deployer.end_drag()
		var guard: int = 0
		while deployer.is_towing(0) and guard < 3000:
			deployer.tow_step(0.1)
			guard += 1
			worst_fortress = minf(worst_fortress, _flat(layout.satellite_centers[0], layout.fortress_center))
			for j: int in range(1, layout.satellite_centers.size()):
				worst_island = minf(worst_island, _flat(layout.satellite_centers[0], layout.satellite_centers[j]))
		deployer.decline()
		guard = 0
		while deployer.is_towing(0) and guard < 3000:
			deployer.tow_step(0.1)
			guard += 1
	assert_gte(worst_island, layout.satellite_radius * 2.0 - 0.05, "chồng đảo vệ tinh khác")
	assert_gte(worst_fortress, reach + layout.satellite_radius - 0.5, "chồng mỏm bến của đảo chính")


func test_outpost_limit_depends_on_level_and_difficulty() -> void:
	assert_eq(LAYOUT.fixed_outposts(), 4, "4 nhà giàn, không đảo cấp sẵn")
	assert_eq(LAYOUT.outpost_limit(Difficulty.Level.EASY), 16)
	assert_eq(LAYOUT.outpost_limit(Difficulty.Level.NORMAL), 14)
	assert_eq(LAYOUT.outpost_limit(Difficulty.Level.HARD), 12)
	assert_eq(LAYOUT.extra_satellites(Difficulty.Level.EASY), 12, "tối đa mua 12 đảo")
	assert_eq(LAYOUT.extra_satellites(Difficulty.Level.NORMAL), 10)
	assert_eq(LAYOUT.extra_satellites(Difficulty.Level.HARD), 8)


func test_total_outposts_never_exceed_the_limit_at_any_difficulty() -> void:
	Profile.set_gold(1000000)
	for level: int in 3:
		Profile.reset_to_new()
		Profile.set_gold(1000000)
		Profile.difficulty = level
		while Profile.buy_island():
			pass
		assert_lte(Profile.outpost_total(), maxi(LAYOUT.outpost_limit(level), LAYOUT.fixed_outposts()), "độ khó %d" % level)
		var layout: MapLayout = Profile.battle_layout(LAYOUT)
		assert_eq(layout.satellite_centers.size() + layout.platform_centers.size(), Profile.outpost_total())


func test_harder_difficulty_trims_bought_islands_but_keeps_them() -> void:
	Profile.set_gold(1000000)
	Profile.difficulty = Difficulty.Level.EASY
	for i: int in 12:
		assert_true(Profile.buy_island())
	assert_false(Profile.buy_island(), "tối đa 12 đảo phụ")
	Profile.difficulty = Difficulty.Level.HARD
	assert_eq(Profile.usable_bought_islands(), 8)
	assert_eq(Profile.bought_islands, 12, "đảo đã mua không mất khi đổi độ khó")
	assert_eq(Profile.battle_layout(LAYOUT).satellite_centers.size(), 8)
	Profile.difficulty = Difficulty.Level.NORMAL
	assert_eq(Profile.usable_bought_islands(), 10)


func test_difficulty_is_saved_and_loaded() -> void:
	Profile.difficulty = Difficulty.Level.HARD
	assert_true(Profile.save(TEMP_PATH, true))
	Profile.difficulty = Difficulty.Level.EASY
	assert_true(Profile.load_saved(TEMP_PATH))
	assert_eq(Profile.difficulty, Difficulty.Level.HARD)
	assert_eq(Difficulty.from_id(&"easy"), Difficulty.Level.EASY)
	assert_eq(Difficulty.from_id(&"xyz"), Difficulty.Level.NORMAL)


func test_main_island_always_has_six_pads_in_every_map() -> void:
	var dir: DirAccess = DirAccess.open("res://data/maps")
	var checked: int = 0
	for file: String in dir.get_files():
		if file.ends_with(".tres"):
			var layout: MapLayout = load("res://data/maps/" + file) as MapLayout
			assert_eq(layout.pier_pad_count(), MapLayout.MAIN_ISLAND_PADS, "%s: đảo chính luôn 6 bệ" % file)
			checked += 1
	assert_gt(checked, 0)
	var battle_layout: MapLayout = Profile.battle_layout(LAYOUT)
	assert_eq(battle_layout.pier_pad_count(), 6)
