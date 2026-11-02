extends GutTest
## Cấu trúc đảo chính: sáu công trình, hiệu ứng tăng theo cấp; Tường Chắn Sóng tăng Độ Nổi tối đa, Trạm Năng Lượng kéo dài MEGA.

const MACHINE_GUN: TowerData = preload("res://data/towers/machine_gun.tres")
const IDS: Array[StringName] = [&"wave_shield", &"repair_works", &"tidal_power", &"radar_station", &"shipyard", &"airfield"]


func before_each() -> void:
	Profile.reset_to_new()


func after_all() -> void:
	Profile.reset_to_new()


func test_main_island_has_the_six_buildings() -> void:
	var ids: Array[StringName] = []
	for data: BuildingData in Profile.buildings():
		ids.append(data.id)
	for id: StringName in IDS:
		assert_true(ids.has(id), String(id))
	assert_eq(ids.size(), 6)


func test_every_building_has_text_and_an_effect_that_grows_with_level() -> void:
	for data: BuildingData in Profile.buildings():
		assert_ne(tr(data.name_key), String(data.name_key), "thiếu tên %s" % data.id)
		assert_ne(tr(data.description_key), String(data.description_key), "thiếu mô tả %s" % data.id)
		assert_ne(data.effect_kind, &"", String(data.id))
		assert_ne(tr(data.effect_key), String(data.effect_key), "thiếu chữ hiệu ứng %s" % data.id)
		assert_gt(data.effect_at(5), data.effect_at(1), "%s: cấp cao mạnh hơn" % data.id)
		assert_almost_eq(data.effect_at(0), data.effect_at(1), 0.0001)
		assert_almost_eq(data.effect_at(9), data.effect_at(5), 0.0001)


func test_level_one_keeps_current_balance() -> void:
	assert_almost_eq(Profile.buoyancy_scale(), 1.0, 0.0001)
	assert_almost_eq(Profile.mega_duration_scale(), 1.0, 0.0001)


func test_wave_wall_raises_max_buoyancy() -> void:
	Profile.building_levels[&"wave_shield"] = 5
	assert_almost_eq(Profile.buoyancy_scale(), 1.4, 0.0001)
	var battle: BattleController = load("res://battle/battle.tscn").instantiate()
	add_child_autofree(battle)
	await get_tree().process_frame
	assert_eq(battle.buoyancy.max_value, roundi(float(battle.layout.starting_buoyancy) * 1.4))
	assert_eq(battle.buoyancy.value, battle.buoyancy.max_value)


func test_tidal_power_lengthens_mega() -> void:
	var plain: Overload = Overload.new(MACHINE_GUN)
	Profile.building_levels[&"tidal_power"] = 5
	var boosted: Overload = Overload.new(MACHINE_GUN)
	boosted.duration_scale = Profile.mega_duration_scale()
	for o: Overload in [plain, boosted]:
		o.state = Overload.State.READY
		assert_true(o.activate())
	assert_almost_eq(boosted.time_left, plain.time_left * 1.4, 0.0001)


func test_tower_picks_up_mega_scale_from_the_base() -> void:
	Profile.building_levels[&"tidal_power"] = 3
	var battle: BattleController = load("res://battle/battle.tscn").instantiate()
	add_child_autofree(battle)
	await get_tree().process_frame
	battle.economy.reset(1000)
	var tower: Tower = battle.build_tower(battle.island.pads[0], MACHINE_GUN)
	assert_almost_eq(tower.overload.duration_scale, 1.2, 0.0001)


func test_unfinished_effects_are_flagged_on_the_base_screen() -> void:
	TranslationServer.set_locale("vi")
	var screen: BaseScreen = BaseScreen.new()
	add_child_autofree(screen)
	await wait_process_frames(2)
	assert_false(screen.effect_text(&"wave_shield").contains(tr(&"BUILDING_NOT_ACTIVE")))
	assert_string_contains(screen.effect_text(&"wave_shield"), "+0%")
	assert_string_contains(screen.effect_text(&"radar_station"), tr(&"BUILDING_NOT_ACTIVE"))
	Profile.building_levels[&"wave_shield"] = 3
	screen.refresh()
	assert_string_contains(screen.effect_text(&"wave_shield"), "+20%")
	for id: StringName in IDS:
		assert_not_null(screen.upgrade_button(id), String(id))
