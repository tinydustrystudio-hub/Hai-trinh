extends GutTest
## Ánh sáng theo màn (P6): ba kiểu ánh sáng nạp được, áp đúng vào nắng, môi trường, biển và viền tối;
## thời tiết và ánh sáng lấy từ bản đồ, cố định suốt màn.

const LAYOUT: MapLayout = preload("res://data/maps/north_dock_layout.tres")


func test_all_lightings_load() -> void:
	for id: StringName in Lighting.ORDER:
		var data: LightingData = Lighting.by_id(id)
		assert_not_null(data, String(id))
		assert_eq(data.id, id)
		assert_gt(data.sun_energy, 0.5)
		assert_gt(data.sun_direction.y, 0.0, "nắng phải ở phía trên mặt nước")
	assert_eq(Lighting.by_id(&"không có").id, &"day", "id lạ về ban ngày")


func test_lightings_look_different() -> void:
	var day: LightingData = Lighting.by_id(&"day")
	var dawn: LightingData = Lighting.by_id(&"dawn")
	var dusk: LightingData = Lighting.by_id(&"dusk")
	assert_ne(day.sun_color, dawn.sun_color)
	assert_ne(dawn.sky_horizon, dusk.sky_horizon)
	assert_lt(dawn.sun_direction.y, day.sun_direction.y, "bình minh nắng thấp hơn, bóng dài hơn")
	assert_lt(dusk.sun_direction.y, day.sun_direction.y)
	assert_gt(dusk.vignette, day.vignette)


func test_apply_sets_sun_environment_and_vignette() -> void:
	var data: LightingData = Lighting.by_id(&"dusk")
	var environment: Environment = Environment.new()
	var sun: DirectionalLight3D = autofree(DirectionalLight3D.new())
	var vignette: Vignette = Vignette.new()
	add_child_autofree(vignette)
	await wait_process_frames(1)
	Lighting.apply(data, environment, sun, null, vignette)
	assert_eq(sun.light_color, data.sun_color)
	assert_almost_eq(sun.light_energy, data.sun_energy, 0.001)
	assert_eq(environment.ambient_light_color, data.ambient_color)
	assert_almost_eq(environment.adjustment_contrast, data.contrast, 0.001)
	assert_almost_eq(environment.glow_hdr_threshold, data.glow_threshold, 0.001)
	assert_almost_eq(vignette.strength, data.vignette, 0.001)


func test_map_declares_fixed_weather_and_lighting() -> void:
	assert_eq(LAYOUT.weather_id, &"clear")
	assert_eq(LAYOUT.lighting_id, &"dawn")
	assert_eq(Weather.by_id(LAYOUT.weather_id).id, &"clear")


func test_battle_uses_map_lighting_and_weather() -> void:
	var battle: BattleController = load("res://battle/battle.tscn").instantiate()
	add_child_autofree(battle)
	await get_tree().process_frame
	assert_eq(battle.lighting.id, &"dawn")
	assert_eq(battle.weather.data.id, &"clear")
	assert_eq(battle.layout.sun_direction, battle.lighting.sun_direction)
	assert_eq(battle.sun.light_color, battle.lighting.sun_color)
	# Thời tiết không tự đổi giữa màn dù thời gian trôi.
	for i: int in 200:
		battle.weather.advance(0.5, 0.5 * float(i))
	assert_eq(battle.weather.data.id, &"clear")


func test_set_lighting_rebuilds_shadows_and_sun() -> void:
	var battle: BattleController = load("res://battle/battle.tscn").instantiate()
	add_child_autofree(battle)
	await get_tree().process_frame
	battle.set_lighting(&"dusk")
	assert_eq(battle.lighting.id, &"dusk")
	assert_eq(battle.sun.light_color, Lighting.by_id(&"dusk").sun_color)
	assert_eq(battle.layout.sun_direction, Lighting.by_id(&"dusk").sun_direction)


func test_vignette_off_at_low_quality() -> void:
	var battle: BattleController = load("res://battle/battle.tscn").instantiate()
	add_child_autofree(battle)
	await get_tree().process_frame
	var before: Ocean.Quality = Settings.water_quality
	Settings.water_quality = Ocean.Quality.LOW
	assert_false(battle.vignette.visible)
	Settings.water_quality = Ocean.Quality.HIGH
	assert_true(battle.vignette.visible)
	Settings.water_quality = before
