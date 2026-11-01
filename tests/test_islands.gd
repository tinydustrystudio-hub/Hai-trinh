extends GutTest
## Đảo vệ tinh (P5c): ô đặt hợp lệ, mua, đặt, dời, cất, phí dùng, bố cục trận theo hồ sơ, lưu và nạp, trang Đảo ở màn Căn cứ.

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


func test_slots_do_not_overlap_each_other_or_fortress() -> void:
	for a: int in LAYOUT.slot_count():
		assert_gt(_flat(LAYOUT.satellite_slots[a], LAYOUT.fortress_center), LAYOUT.fortress_radius * 2.0, "ô %d sát đảo chính" % a)
		for b: int in range(a + 1, LAYOUT.slot_count()):
			assert_gte(_flat(LAYOUT.satellite_slots[a], LAYOUT.satellite_slots[b]), LAYOUT.satellite_radius * 2.0 + 2.0, "ô %d và %d chồng nhau" % [a, b])


func test_new_player_has_four_placed_free_islands() -> void:
	assert_eq(Profile.island_total(), 4)
	assert_eq(Profile.placed_count(), 4)
	assert_eq(Profile.bought_islands, 0)
	assert_eq(Profile.battle_islands().size(), 4)


func test_buy_island_costs_and_goes_to_storage() -> void:
	Profile.set_gold(1000)
	assert_eq(Profile.island_buy_cost(), 250)
	assert_true(Profile.buy_island())
	assert_eq(Profile.gold, 750)
	assert_eq(Profile.island_total(), 5)
	assert_eq(Profile.islands[4], -1)
	assert_eq(Profile.island_buy_cost(), 300, "mỗi đảo sau +50")


func test_cannot_buy_without_gold_or_beyond_max() -> void:
	Profile.set_gold(100)
	assert_false(Profile.buy_island())
	Profile.set_gold(100000)
	for i: int in 10:
		Profile.buy_island()
	assert_eq(Profile.bought_islands, Profile.max_bought_islands())
	assert_eq(Profile.island_total(), LAYOUT.satellite_max_count)


func test_placing_stored_island_is_free_and_limited_to_max() -> void:
	Profile.set_gold(100000)
	Profile.buy_island()
	var before: int = Profile.gold
	assert_true(Profile.place_island(4, 4))
	assert_eq(Profile.gold, before, "đặt đảo từ kho miễn phí")
	assert_eq(Profile.placed_count(), 5)
	assert_false(Profile.place_island(4, 4), "ô đã có đảo")
	for i: int in 3:
		Profile.buy_island()
	for i: int in 3:
		Profile.place_island(5 + i, 5 + i)
	assert_eq(Profile.placed_count(), 8)
	Profile.buy_island()
	assert_false(Profile.place_island(Profile.islands.size() - 1, 9) and Profile.placed_count() > 8)


func test_moving_costs_half_cheapest_tower() -> void:
	var cheapest: int = Profile.cheapest_tower_cost()
	assert_eq(Profile.island_move_cost(), cheapest / 2)
	Profile.set_gold(500)
	assert_true(Profile.place_island(0, 4))
	assert_eq(Profile.gold, 500 - cheapest / 2)
	assert_eq(Profile.islands[0], 4)
	Profile.set_gold(1)
	assert_false(Profile.place_island(1, 5), "thiếu vàng dời")
	assert_eq(Profile.islands[1], 1)


func test_store_island_is_free() -> void:
	assert_true(Profile.store_island(0))
	assert_eq(Profile.placed_count(), 3)
	assert_eq(Profile.gold, Profile.NEW_PLAYER_GOLD)
	assert_false(Profile.store_island(0))


func test_use_fee_only_for_self_placed_islands() -> void:
	Profile.set_gold(100000)
	assert_eq(Profile.use_fee(Profile.battle_islands()), 0, "đảo cấp sẵn miễn phí")
	Profile.buy_island()
	Profile.buy_island()
	Profile.place_island(4, 4)
	Profile.place_island(5, 5)
	assert_eq(Profile.use_fee(Profile.battle_islands()), 200 + 250)


func test_unaffordable_self_islands_are_left_out_of_battle() -> void:
	Profile.set_gold(100000)
	Profile.buy_island()
	Profile.buy_island()
	Profile.place_island(4, 4)
	Profile.place_island(5, 5)
	Profile.set_gold(220)
	var used: Array[int] = Profile.battle_islands()
	assert_true(used.has(4))
	assert_false(used.has(5), "đảo thứ hai tự đặt (250) không đủ vàng")
	assert_eq(Profile.charge_use_fee(used), 200)
	assert_eq(Profile.gold, 20)


func test_battle_layout_follows_placement() -> void:
	Profile.store_island(3)
	Profile.set_gold(100000)
	Profile.buy_island()
	Profile.place_island(4, 6)
	var used: Array[int] = Profile.battle_islands()
	var layout: MapLayout = Profile.battle_layout(LAYOUT, used)
	assert_eq(layout.satellite_centers.size(), 4)
	assert_true(layout.satellite_centers.has(LAYOUT.satellite_slots[6]))
	assert_false(layout.satellite_centers.has(LAYOUT.satellite_slots[3]))
	assert_eq(layout.pad_count(), 6 + 4)
	for i: int in layout.pad_count():
		if i >= 6:
			assert_true(layout.is_satellite_pad(i))


func test_battle_builds_islands_from_profile() -> void:
	Profile.store_island(2)
	var battle: BattleController = load("res://battle/battle.tscn").instantiate()
	add_child_autofree(battle)
	await get_tree().process_frame
	assert_eq(battle.layout.satellite_centers.size(), 3)
	assert_eq(battle.island.satellites.size(), 3)
	assert_eq(battle.island.pads.size(), 9)


func test_save_and_load_islands() -> void:
	Profile.set_gold(100000)
	Profile.buy_island()
	Profile.place_island(4, 7)
	Profile.store_island(1)
	assert_true(Profile.save(TEMP_PATH, true))
	var saved: Array[int] = Profile.islands.duplicate()
	Profile.reset_to_new()
	assert_true(Profile.load_saved(TEMP_PATH))
	assert_eq(Profile.islands, saved)
	assert_eq(Profile.bought_islands, 1)


func test_load_ignores_bad_island_data() -> void:
	Profile.apply_dictionary({"gold": 10, "islands": [0, 0, 99, "x", 3], "bought": 99})
	assert_eq(Profile.bought_islands, Profile.max_bought_islands())
	assert_eq(Profile.islands[0], 0)
	assert_eq(Profile.islands[1], 1, "ô trùng thì giữ mặc định")
	assert_eq(Profile.island_total(), 4 + Profile.max_bought_islands())


func test_island_panel_tap_flow() -> void:
	var panel: IslandPanel = IslandPanel.new()
	add_child_autofree(panel)
	await wait_process_frames(2)
	TranslationServer.set_locale("vi")
	panel.tap_slot(8)
	assert_eq(panel.status_text(), "Không còn đảo trong kho, hãy mua thêm.")
	Profile.set_gold(1000)
	panel.buy_button().pressed.emit()
	assert_eq(Profile.island_total(), 5)
	panel.tap_slot(8)
	assert_eq(Profile.island_at_slot(8), 4)
	assert_eq(Profile.gold, 750, "đặt miễn phí")
	panel.tap_slot(9)
	assert_eq(Profile.island_at_slot(9), 4, "đảo vừa đặt đang được chọn nên chạm ô trống là dời")
	assert_eq(Profile.gold, 750 - Profile.island_move_cost())
	panel.store_button().pressed.emit()
	assert_eq(Profile.islands[4], -1)
	panel.reset_button().pressed.emit()
	assert_eq(Profile.placed_count(), 4)


func test_base_screen_island_page_and_tap_picking() -> void:
	TranslationServer.set_locale("vi")
	var screen: BaseScreen = BaseScreen.new()
	add_child_autofree(screen)
	await wait_process_frames(2)
	assert_eq(screen.page(), 0)
	assert_false(screen.island_panel().visible)
	screen.tab_islands_button().pressed.emit()
	assert_eq(screen.page(), 1)
	assert_true(screen.island_panel().visible)
	assert_false(screen.upgrade_button(&"shipyard").get_parent().get_parent().get_parent().visible)
	var empty_slot: int = 6
	var point: Vector2 = screen.slot_screen_position(empty_slot)
	assert_eq(screen.slot_at(point), empty_slot)
	assert_eq(screen.slot_at(Vector2(-500, -500)), -1)
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = point
	var release: InputEventMouseButton = press.duplicate() as InputEventMouseButton
	release.pressed = false
	Profile.set_gold(1000)
	Profile.buy_island()
	screen.get_node("Preview").gui_input.emit(press)
	screen.get_node("Preview").gui_input.emit(release)
	assert_eq(Profile.island_at_slot(empty_slot), 4, "chạm ô trống đặt đảo từ kho")
	assert_eq(screen.island().satellites.size(), 5)
	screen.tab_buildings_button().pressed.emit()
	assert_true(screen.upgrade_button(&"shipyard").visible)
