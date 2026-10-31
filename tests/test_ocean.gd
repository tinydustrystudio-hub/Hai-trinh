extends GutTest
## Độ cao sóng trên CPU: biên độ của một sóng bằng độ dốc ÷ số sóng k.

func test_single_wave_amplitude() -> void:
	var waves: Array[Vector4] = [Vector4(1, 0, 0.1, 20.0)]
	var k: float = TAU / 20.0
	var amplitude: float = 0.1 / k
	# Đỉnh sóng ở x = bước sóng/4 khi t = 0.
	assert_almost_eq(Ocean.wave_height(waves, 1, 5.0, 0.0, 0.0), amplitude, 0.0001)
	assert_almost_eq(Ocean.wave_height(waves, 1, 0.0, 0.0, 0.0), 0.0, 0.0001)


func test_wave_count_limits_layers() -> void:
	var waves: Array[Vector4] = [Vector4(1, 0, 0.1, 20.0), Vector4(0, 1, 0.1, 10.0)]
	var one: float = Ocean.wave_height(waves, 1, 3.0, 2.0, 0.5)
	var both: float = Ocean.wave_height(waves, 2, 3.0, 2.0, 0.5)
	var second_only: float = Ocean.wave_height([waves[1]] as Array[Vector4], 1, 3.0, 2.0, 0.5)
	assert_almost_eq(both, one + second_only, 0.0001)


func test_zero_waves_is_flat() -> void:
	var waves: Array[Vector4] = [Vector4(1, 0, 0.1, 20.0)]
	assert_eq(Ocean.wave_height(waves, 0, 3.0, 2.0, 0.5), 0.0)


func test_highlight_sits_behind_island_along_view() -> void:
	# Camera nhìn về phía Bắc (−z): vệt sáng nằm phía Bắc đảo, ngay sau đảo theo hướng nhìn.
	var center: Vector2 = Ocean.highlight_center(Vector3(0, 0, 0), 14.0, Vector3(0, -0.8, -0.57))
	assert_almost_eq(center.x, 0.0, 0.0001)
	assert_almost_eq(center.y, -14.0 * Ocean.HIGHLIGHT_DISTANCE, 0.0001)
	assert_gt(Ocean.HIGHLIGHT_DISTANCE, 1.0, "vệt sáng ở ngoài đảo, không đè lên đảo")


func test_highlight_ignores_sun_direction() -> void:
	# Hàm không nhận hướng nắng: đổi nắng không làm vệt sáng dồn về góc nào.
	var a: Vector2 = Ocean.highlight_center(Vector3(5, 0, 3), 10.0, Vector3(0, -1, -1))
	assert_eq(a, Vector2(5, 3) + Vector2(0, -1) * 10.0 * Ocean.HIGHLIGHT_DISTANCE)


func test_generated_waves_are_irregular_but_gentle() -> void:
	# Góp ý 3: sóng ngẫu nhiên, không chạy chéo đều một hướng, một chu kỳ.
	var generated: Array = Ocean.make_waves(Ocean.WAVE_SEED)
	var waves: Array[Vector4] = generated[0]
	var shapes: Array[Vector4] = generated[1]
	var motions: Array[Vector4] = generated[2]
	assert_eq(waves.size(), Ocean.MAX_WAVES)
	assert_eq(shapes.size(), Ocean.MAX_WAVES)
	var min_angle: float = INF
	var max_angle: float = -INF
	var lengths: Dictionary = {}
	var base: float = atan2(waves[0].y, waves[0].x)
	for wave: Vector4 in waves:
		var angle: float = wrapf(atan2(wave.y, wave.x) - base, -PI, PI)
		min_angle = minf(min_angle, angle)
		max_angle = maxf(max_angle, angle)
		lengths[snappedf(wave.w, 0.1)] = true
	assert_gt(max_angle - min_angle, 0.8, "các lớp sóng lệch hướng nhau")
	assert_eq(lengths.size(), Ocean.MAX_WAVES, "bước sóng không trùng nhau")
	# Ở bất kỳ đâu, bất kỳ lúc nào cũng không cao hơn MAX_WAVE_HEIGHT.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5
	var highest: float = 0.0
	for i: int in 500:
		var h: float = Ocean.wave_height(waves, waves.size(), rng.randf_range(-150, 150), rng.randf_range(-150, 150), rng.randf_range(0, 100), shapes, motions)
		highest = maxf(highest, absf(h))
	assert_lte(highest, Ocean.MAX_WAVE_HEIGHT + 0.0001)
	assert_gt(highest, Ocean.MAX_WAVE_HEIGHT * 0.3, "vẫn có sóng")


func test_same_seed_same_sea() -> void:
	assert_eq(Ocean.make_waves(3), Ocean.make_waves(3))
	assert_ne(Ocean.make_waves(3), Ocean.make_waves(4))


func test_crest_modulation_varies_along_crest() -> void:
	# Cùng một ngọn sóng (đi dọc vuông góc với hướng sóng), biên độ đổi dần chứ không đều.
	var shape: Vector4 = Vector4(0.0, 0.3, 0.0, 0.5)
	var k: float = TAU / 20.0
	var a: float = Ocean.crest_modulation(shape, Vector2(1, 0), k, 0.0, 0.0, 0.0)
	var b: float = Ocean.crest_modulation(shape, Vector2(1, 0), k, 0.0, 20.0 / 0.3 / 4.0, 0.0)
	assert_almost_eq(a, 1.0, 0.0001)
	assert_almost_eq(b, 1.5, 0.0001)


func test_waves_vary_in_height_and_speed() -> void:
	# Góp ý 4: sóng không còn cao bằng nhau, tốc độ đều đều.
	var generated: Array = Ocean.make_waves(Ocean.WAVE_SEED)
	var waves: Array[Vector4] = generated[0]
	var shapes: Array[Vector4] = generated[1]
	var motions: Array[Vector4] = generated[2]
	var speeds: Array[float] = []
	for motion: Vector4 in motions:
		speeds.append(motion.x)
	assert_gt(speeds.max() - speeds.min(), 0.25, "mỗi lớp sóng chạy một tốc độ")
	# Dọc một đường ngang, độ cao đỉnh sóng đổi nhiều từ chỗ này sang chỗ khác.
	var peaks: Array[float] = []
	for window: int in 12:
		var top: float = 0.0
		for i: int in 60:
			var x: float = float(window) * 40.0 + float(i) * 0.7
			top = maxf(top, Ocean.wave_height(waves, waves.size(), x, 0.0, 12.0, shapes, motions))
		peaks.append(top)
	assert_gt(peaks.max() / maxf(peaks.min(), 0.001), 1.5, "có chỗ sóng to chỗ sóng nhỏ")
	# Cùng một chỗ, độ cao đỉnh cũng đổi theo thời gian.
	var over_time: Array[float] = []
	for t: int in 10:
		var top: float = 0.0
		for i: int in 60:
			top = maxf(top, Ocean.wave_height(waves, waves.size(), float(i) * 0.7, 0.0, float(t) * 20.0, shapes, motions))
		over_time.append(top)
	assert_gt(over_time.max() / maxf(over_time.min(), 0.001), 1.2)
