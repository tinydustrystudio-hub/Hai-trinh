extends GutTest
## Nhà giàn cố định trên biển của từng màn: giàn khoan dầu khí cũ ở màn Bến Bắc, mỗi nhà giàn mang một bệ lô cốt.

const LAYOUT: MapLayout = preload("res://data/maps/north_dock_layout.tres")
const MACHINE_GUN: TowerData = preload("res://data/towers/machine_gun.tres")

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


func before_each() -> void:
	Profile.reset_to_new()


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _new_battle() -> BattleController:
	var battle: BattleController = load("res://battle/battle.tscn").instantiate()
	add_child_autofree(battle)
	await get_tree().process_frame
	battle.economy.reset(5000)
	return battle


func test_north_dock_has_four_old_oil_rigs() -> void:
	assert_eq(LAYOUT.platform_centers.size(), 4)
	for k: int in 4:
		assert_eq(LAYOUT.platform_kind(k), &"old_oil_rig")
		assert_true(Platforms.has_model(LAYOUT.platform_kind(k)))


func test_platforms_are_clear_and_reach_a_lane() -> void:
	var reach: float = 2.5 * TowerData.RANGE_BONUS * MapLayout.UNITS_PER_CELL
	for k: int in LAYOUT.platform_centers.size():
		var center: Vector3 = LAYOUT.platform_centers[k]
		assert_gt(_flat(center, LAYOUT.fortress_center), LAYOUT.fortress_radius * 2.0, "giàn %d sát đảo chính" % k)
		var nearest: float = INF
		for lane: Lane in _lanes:
			nearest = minf(nearest, lane.distance_to(center))
		assert_gt(nearest, LAYOUT.platform_radius + Lane.RIBBON_WIDTH * 0.5, "giàn %d đè luồng" % k)
		assert_lte(nearest, reach, "bệ giàn %d không với tới luồng" % k)
		for other: Vector3 in LAYOUT.satellite_centers:
			assert_gt(_flat(center, other), LAYOUT.platform_radius + LAYOUT.satellite_radius, "giàn %d chồng đảo vệ tinh" % k)
		for dock: Vector3 in LAYOUT.satellite_docks:
			assert_gt(_flat(center, dock), LAYOUT.platform_radius + LAYOUT.satellite_radius, "giàn %d chồng chỗ đậu" % k)
		for j: int in range(k + 1, LAYOUT.platform_centers.size()):
			assert_gt(_flat(center, LAYOUT.platform_centers[j]), LAYOUT.platform_radius * 2.0)


func test_each_platform_has_exactly_one_pad_and_pads_are_ordered() -> void:
	for k: int in LAYOUT.platform_centers.size():
		var pads: int = 0
		for i: int in LAYOUT.pad_count():
			if LAYOUT.platform_index_of_pad(i) == k:
				pads += 1
				assert_false(LAYOUT.is_pier_pad(i))
				assert_false(LAYOUT.is_satellite_pad(i))
		assert_eq(pads, 1)
	var piers: int = 0
	for i: int in LAYOUT.pad_count():
		if LAYOUT.is_pier_pad(i):
			piers += 1
	assert_eq(piers, 6)


func test_old_oil_rig_model_is_in_budget() -> void:
	var mesh: ArrayMesh = ModelMesh.load_mesh(Platforms.model_name(Platforms.OLD_OIL_RIG))
	assert_not_null(mesh)
	assert_lt(mesh.surface_get_array_len(0) / 3, 3000, "ngân sách tam giác mỗi nhà giàn")
	var box: AABB = mesh.get_aabb()
	assert_gt(box.end.y, Platforms.deck_height(Platforms.OLD_OIL_RIG) + 4.0, "có tháp khoan cao")
	assert_lt(maxf(box.size.x, box.size.z), LAYOUT.platform_radius * 2.0 + 2.0, "nằm trong bán kính chiếm chỗ")


func test_island_builds_platform_nodes_with_pad_on_deck() -> void:
	var battle: BattleController = await _new_battle()
	assert_eq(battle.island.platforms.size(), 4)
	for k: int in 4:
		var platform: Node3D = battle.island.platforms[k]
		assert_not_null(platform.get_node_or_null("Model"))
		assert_almost_eq(platform.position.x, LAYOUT.platform_centers[k].x, 0.001)
	var pad: TowerPad = battle.island.pads[6]
	assert_eq(pad.get_parent(), battle.island.platforms[0])
	assert_almost_eq(pad.global_position.y + TowerPad.TOP_HEIGHT, Platforms.deck_height(Platforms.OLD_OIL_RIG), 0.1, "mặt bệ ngang mặt sàn")


func test_tower_can_be_built_on_platform_and_picked_by_tap() -> void:
	var battle: BattleController = await _new_battle()
	var pad: TowerPad = battle.island.pads[6]
	var screen: Vector2 = battle.camera.unproject_position(pad.global_position + Vector3(0, TowerPad.TOP_HEIGHT, 0))
	assert_eq(battle.pad_at(screen), pad, "chạm đúng bệ trên sàn cao")
	var tower: Tower = battle.build_tower(pad, MACHINE_GUN)
	assert_not_null(tower)
	assert_eq(tower.get_parent(), pad)
	assert_gt(tower.global_position.y, 1.0, "lô cốt đứng trên sàn")


func test_tower_moves_between_platform_and_pier() -> void:
	var battle: BattleController = await _new_battle()
	var tower: Tower = battle.build_tower(battle.island.pads[0], MACHINE_GUN)
	assert_true(battle.move_tower(tower, battle.island.pads[6]))
	assert_eq(tower.pad, battle.island.pads[6])
	assert_true(battle.move_tower(tower, battle.island.pads[1]))
	assert_eq(tower.pad, battle.island.pads[1])


func test_towed_island_cannot_be_placed_on_a_platform() -> void:
	for center: Vector3 in LAYOUT.platform_centers:
		assert_false(LAYOUT.island_spot_valid(center))
		assert_false(LAYOUT.island_spot_valid(center + Vector3(LAYOUT.platform_radius, 0, 0)))
