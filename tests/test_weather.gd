extends GutTest
## Thời tiết (góp ý 4, mục 12): bình thường như hiện tại; mưa sóng to hơn và có mưa; bão sóng lớn, sấm sét,
## gió đổi chiều liên tục. Chuyển mượt, chỉ đổi hình ảnh và âm thanh.

const BATTLE_SCENE: PackedScene = preload("res://battle/battle.tscn")

var _battle: BattleController


func before_each() -> void:
	_battle = add_child_autofree(BATTLE_SCENE.instantiate())


func test_three_kinds_get_stronger() -> void:
	var clear: WeatherData = Weather.by_id(&"clear")
	var rain: WeatherData = Weather.by_id(&"rain")
	var storm: WeatherData = Weather.by_id(&"storm")
	assert_eq(clear.wave_boost, 1.0, "bình thường như hiện tại")
	assert_eq(clear.rain, 0.0)
	assert_eq(clear.wind_swing, 0.0)
	assert_false(clear.has_lightning())
	assert_gt(rain.wave_boost, clear.wave_boost, "mưa sóng to hơn")
	assert_gt(rain.rain, 0.0, "và có mưa")
	assert_false(rain.has_lightning())
	assert_gt(storm.wave_boost, rain.wave_boost, "bão sóng lớn hơn nữa")
	assert_gt(storm.wind_swing, rain.wind_swing, "gió đổi chiều mạnh")
	assert_true(storm.has_lightning(), "có sấm sét")
	assert_gt(storm.rain, rain.rain)
	assert_gt(storm.darkness, rain.darkness)
	assert_eq(Weather.by_id(&"không có"), clear, "lạ thì về bình thường")


func test_starts_clear_by_default() -> void:
	assert_eq(_battle.weather.data.id, &"clear")
	assert_eq(_battle.ocean.wave_boost, 1.0)
	assert_false(_battle.weather.rain_field.is_showing())


func test_transition_is_smooth() -> void:
	_battle.set_weather(&"storm")
	assert_almost_eq(_battle.weather.wave_boost, 1.0, 0.001, "chưa đổi ngay")
	_battle.weather.advance(Weather.TRANSITION_SECONDS * 0.5, 10.0)
	var middle: float = _battle.weather.wave_boost
	assert_gt(middle, 1.0)
	assert_lt(middle, Weather.by_id(&"storm").wave_boost)
	_battle.weather.advance(Weather.TRANSITION_SECONDS, 20.0)
	assert_almost_eq(_battle.weather.wave_boost, Weather.by_id(&"storm").wave_boost, 0.001)
	assert_almost_eq(_battle.ocean.wave_boost, Weather.by_id(&"storm").wave_boost, 0.001, "biển nhận đúng sóng bão")


func test_storm_waves_are_bigger_in_height() -> void:
	var generated: Array = Ocean.make_waves(Ocean.WAVE_SEED)
	var waves: Array[Vector4] = generated[0]
	var shapes: Array[Vector4] = generated[1]
	var motions: Array[Vector4] = generated[2]
	var clear_top: float = 0.0
	var storm_top: float = 0.0
	for i: int in 400:
		var x: float = float(i) * 0.8
		clear_top = maxf(clear_top, absf(Ocean.wave_height(waves, waves.size(), x, 3.0, 9.0, shapes, motions, 1.0, 0.0)))
		storm_top = maxf(storm_top, absf(Ocean.wave_height(waves, waves.size(), x, 3.0, 9.0, shapes, motions, Weather.by_id(&"storm").wave_boost, 0.0)))
	assert_almost_eq(storm_top / clear_top, Weather.by_id(&"storm").wave_boost, 0.01)
	assert_gt(storm_top, 1.2, "sóng bão cao thật (người duyệt 1/11: chiều cao sóng phải lớn)")


func test_wind_changes_direction_continuously() -> void:
	var swing: float = Weather.by_id(&"storm").wind_swing
	var angles: Array[float] = []
	for i: int in 200:
		angles.append(Weather.wind_angle(swing, Weather.by_id(&"storm").wind_period, float(i) * 0.5))
	assert_gt(angles.max(), swing * 0.5, "quay sang một phía")
	assert_lt(angles.min(), -swing * 0.5, "rồi quay sang phía kia")
	assert_lte(angles.max(), swing + 0.0001)
	var changes: int = 0
	for i: int in range(2, angles.size()):
		if (angles[i] - angles[i - 1]) * (angles[i - 1] - angles[i - 2]) < 0.0:
			changes += 1
	assert_gt(changes, 4, "đổi chiều nhiều lần, không một nhịp đều")
	assert_eq(Weather.wind_angle(0.0, 20.0, 5.0), 0.0, "trời quang không có gió đổi chiều")


func test_wind_rotates_wave_directions() -> void:
	var waves: Array[Vector4] = [Vector4(1, 0, 0.1, 20.0)]
	var straight: float = Ocean.wave_height(waves, 1, 5.0, 0.0, 0.0, [], [], 1.0, 0.0)
	var turned: float = Ocean.wave_height(waves, 1, 5.0, 0.0, 0.0, [], [], 1.0, PI * 0.5)
	assert_ne(straight, turned)
	# Quay 90°: sóng chạy dọc trục z nên dọc trục x không còn dao động.
	assert_almost_eq(turned, 0.0, 0.0001)


func test_rain_field_shows_only_when_raining() -> void:
	_battle.set_weather(&"rain")
	_battle.weather.advance(Weather.TRANSITION_SECONDS + 1.0, 5.0)
	assert_true(_battle.weather.rain_field.is_showing())
	assert_almost_eq(_battle.weather.rain_field.rain, Weather.by_id(&"rain").rain, 0.001)
	_battle.set_weather(&"clear")
	_battle.weather.advance(Weather.TRANSITION_SECONDS + 1.0, 15.0)
	assert_false(_battle.weather.rain_field.is_showing(), "hết mưa thì ẩn")


func test_sun_dims_in_storm_and_recovers() -> void:
	var base: float = _battle.sun.light_energy
	_battle.set_weather(&"storm")
	_battle.weather.advance(Weather.TRANSITION_SECONDS + 1.0, 5.0)
	assert_lt(_battle.sun.light_energy, base * 0.8)
	_battle.set_weather(&"clear")
	_battle.weather.advance(Weather.TRANSITION_SECONDS + 1.0, 15.0)
	assert_almost_eq(_battle.sun.light_energy, base, 0.001)


func test_lightning_only_in_storm_and_triggers_thunder() -> void:
	watch_signals(Events)
	_battle.set_weather(&"rain")
	for i: int in 300:
		_battle.weather.advance(0.5, float(i) * 0.5)
	assert_eq(_battle.weather.strikes, 0, "mưa thường không có sét")
	_battle.set_weather(&"storm")
	var elapsed: float = 0.0
	while elapsed < 120.0:
		_battle.weather.advance(0.5, 200.0 + elapsed)
		elapsed += 0.5
	assert_gte(_battle.weather.strikes, 120.0 / Weather.by_id(&"storm").lightning_max_seconds - 1.0)
	assert_lte(_battle.weather.strikes, int(120.0 / Weather.by_id(&"storm").lightning_min_seconds) + 1)
	assert_signal_emitted(Events, "lightning_struck")
	assert_eq(_battle.weather.lightning_overlay.strikes, _battle.weather.strikes)


func test_thunder_sound_exists_and_is_throttled() -> void:
	var board: SoundBoard = add_child_autofree(SoundBoard.new())
	var wav: AudioStreamWAV = board.stream(SoundBoard.Sound.THUNDER)
	assert_not_null(wav)
	assert_almost_eq(wav.get_length(), 1.8, 0.02)
	assert_true(board.play(SoundBoard.Sound.THUNDER))
	assert_false(board.play(SoundBoard.Sound.THUNDER))


func test_bolt_points_run_from_top_toward_sea() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var size: Vector2 = Vector2(1920, 1080)
	var points: PackedVector2Array = LightningOverlay.bolt_points(rng, size, 0.5)
	assert_eq(points.size(), LightningOverlay.BOLT_SEGMENTS + 1)
	assert_eq(points[0].y, 0.0)
	assert_gt(points[points.size() - 1].y, size.y * 0.5)
	assert_almost_eq(points[0].x, size.x * 0.5, 0.001)


func test_weather_is_selectable_by_launch_value() -> void:
	assert_eq(Settings.query_value("?weather=storm&debug", "weather"), "storm")
	assert_eq(Settings.query_value("?debug", "weather"), "")
	assert_eq(Settings.query_value("", "weather"), "")


func test_storm_waves_are_bigger_but_not_faster() -> void:
	# Người duyệt (1/11): bão làm sóng to hơn và đảo dập dìu nhiều hơn, tốc độ không cần quá nhanh.
	var clear: WeatherData = Weather.by_id(&"clear")
	var rain: WeatherData = Weather.by_id(&"rain")
	var storm: WeatherData = Weather.by_id(&"storm")
	assert_gt(storm.wave_boost, 4.5)
	assert_gt(storm.wave_boost, rain.wave_boost)
	assert_lte(storm.wave_speed, rain.wave_speed)
	assert_lte(rain.wave_speed, clear.wave_speed)
	assert_lt(storm.wave_speed, 0.7, "bão chậm hơn bình thường")
	assert_gt(storm.bob_scale, rain.bob_scale)
	assert_gt(rain.bob_scale, clear.bob_scale)
	assert_lte(storm.wind_swing, 0.4, "gió đổi chiều nhưng không làm sóng quay vèo")
	assert_gte(storm.wind_period, 30.0)


func test_sea_clock_follows_speed_without_jumping() -> void:
	_battle.set_weather(&"storm")
	_battle.weather.advance(Weather.TRANSITION_SECONDS + 1.0, 5.0)
	assert_almost_eq(_battle.ocean.sea_speed, Weather.by_id(&"storm").wave_speed, 0.001)
	var before: float = _battle.ocean.sea_time
	_battle.ocean._process(2.0)
	assert_almost_eq(_battle.ocean.sea_time - before, 2.0 * _battle.ocean.sea_speed, 0.0001)
	# Đổi tốc độ không làm sea_time nhảy: chỉ tốc độ tăng sau đó thay đổi.
	var at_change: float = _battle.ocean.sea_time
	_battle.set_weather(&"clear")
	_battle.weather.advance(0.0, 5.0)
	assert_eq(_battle.ocean.sea_time, at_change)


func test_island_bob_scale_follows_weather() -> void:
	assert_eq(_battle.island.bob_scale, 1.0)
	_battle.set_weather(&"storm")
	_battle.weather.advance(Weather.TRANSITION_SECONDS + 1.0, 5.0)
	assert_almost_eq(_battle.island.bob_scale, Weather.by_id(&"storm").bob_scale, 0.001)
	var layout: MapLayout = _battle.layout
	var calm: Vector3 = Island.sample_pose(_battle.ocean, layout.platform_centers[0], layout.satellite_radius, 3.0, 1.0)
	var rough: Vector3 = Island.sample_pose(_battle.ocean, layout.platform_centers[0], layout.satellite_radius, 3.0, 2.4)
	assert_gt(absf(rough.x), absf(calm.x) * 1.5, "bão: đảo nhấp nhô nhiều hơn")


func test_rain_reaches_the_sea_surface() -> void:
	assert_eq(_battle.ocean.rain_amount, 0.0)
	_battle.set_weather(&"rain")
	_battle.weather.advance(Weather.TRANSITION_SECONDS + 1.0, 5.0)
	assert_gt(_battle.ocean.rain_amount, 0.3, "mặt biển có gợn mưa rơi")


func test_rain_is_3d_and_stays_in_world_space() -> void:
	# Người duyệt (1/11): mưa phải rơi xuống biển và công trình trong không gian trận, không phải lớp phủ 2D.
	var field: RainField = _battle.weather.rain_field
	assert_true(field is Node3D)
	assert_eq(field.multimesh.instance_count, RainField.COUNT)
	var area: AABB = field.multimesh.custom_aabb
	assert_gt(area.size.y, RainField.FALL_HEIGHT, "mưa có chiều cao: rơi từ trên xuống")
	assert_gte(area.size.x, 240.0, "phủ vùng nhìn thấy khi thu nhỏ hết cỡ")
	var before: Vector3 = field.global_position
	_battle.camera.set_focus(Vector2(5.0, -7.0))
	_battle.weather.advance(0.1, 1.0)
	_battle.step(0.1)
	assert_eq(field.global_position, before, "mưa đứng yên trong không gian trận khi kéo camera")
	assert_eq(field.focus, _battle.camera.focus, "khối mưa phủ quanh camera nhìn")


func test_rain_amount_scales_streaks_shown() -> void:
	var field: RainField = _battle.weather.rain_field
	field.set_rain(0.25, 0.0)
	assert_eq(field.streaks_shown(), RainField.COUNT / 4)
	field.set_rain(0.0, 0.0)
	assert_false(field.is_showing())


func test_rain_and_storm_surface_is_twice_as_choppy() -> void:
	# Người duyệt (1/11): mưa và bão tăng độ mấp mô mặt nước gấp đôi bản đầu (1,3 và 1,8).
	assert_almost_eq(Weather.by_id(&"rain").chop, 1.3 * 2.0, 0.001)
	assert_almost_eq(Weather.by_id(&"storm").chop, 1.8 * 2.0, 0.001)
	assert_eq(Weather.by_id(&"clear").chop, 1.0, "bình thường giữ nguyên")


func test_waves_calm_down_next_to_islands() -> void:
	# Sóng bão cao nhưng lặng dần gần đảo, để không nhấn chìm sàn đảo.
	var ocean: Ocean = _battle.ocean
	var layout: MapLayout = _battle.layout
	var center: Vector3 = layout.fortress_center
	assert_almost_eq(ocean.calm_factor(center.x, center.z), 0.0, 0.0001, "giữa pháo đài: lặng")
	assert_eq(ocean.calm_factor(center.x + 200.0, center.z + 200.0), 1.0, "xa đảo: sóng đủ")
	var edge: float = layout.fortress_radius + 5.0
	assert_lt(ocean.calm_factor(center.x + edge + 2.0, center.z), 0.5)
	assert_gt(ocean.calm_factor(center.x + edge + Ocean.CALM_MARGIN, center.z), 0.99)
	_battle.set_weather(&"storm")
	_battle.weather.advance(Weather.TRANSITION_SECONDS + 1.0, 5.0)
	var near: float = 0.0
	var far: float = 0.0
	for t: int in 40:
		ocean.sea_time = float(t) * 1.7
		near = maxf(near, absf(ocean.height_at(center.x + edge, center.z)))
		far = maxf(far, absf(ocean.height_at(center.x + edge + 60.0, center.z + 40.0)))
	assert_lt(near, 0.35, "sàn đảo không bị sóng bão nuốt")
	assert_gt(far, 0.8, "xa đảo sóng bão cao")
	assert_gt(absf(ocean.raw_height_at(center.x, center.z)) + 1.0, 0.0)
	for center_disc: Vector3 in layout.satellite_centers:
		assert_almost_eq(ocean.calm_factor(center_disc.x, center_disc.z), 0.0, 0.0001)


func test_island_heave_is_limited_so_decks_stay_above_water() -> void:
	var ocean: Ocean = _battle.ocean
	_battle.set_weather(&"storm")
	_battle.weather.advance(Weather.TRANSITION_SECONDS + 1.0, 5.0)
	var low: float = 0.0
	var high: float = 0.0
	for t: int in 80:
		ocean.sea_time = float(t) * 1.3
		var pose: Vector3 = Island.sample_pose(ocean, _battle.layout.platform_centers[1], _battle.layout.satellite_radius, 0.0, 2.4)
		low = minf(low, pose.x)
		high = maxf(high, pose.x)
	assert_gte(low, Island.HEAVE_MIN - 0.0001)
	assert_lte(high, Island.HEAVE_MAX + 0.0001)
	assert_gt(high - low, 0.3, "vẫn dập dìu rõ")
