extends GutTest
## Texture nhiễu của nước được dựng sẵn thành ảnh (P7), không sinh lúc vào trận.

func test_baked_textures_exist_and_have_expected_size() -> void:
	for spec: Dictionary in Ocean.NOISE_SPECS:
		var path: String = "res://assets/textures/%s.png" % spec["name"]
		assert_true(ResourceLoader.exists(path), path)
		var texture: Texture2D = load(path) as Texture2D
		assert_not_null(texture, path)
		assert_eq(texture.get_width(), Ocean.NORMAL_MAP_SIZE, path)
		assert_eq(texture.get_height(), Ocean.NORMAL_MAP_SIZE, path)


func test_ocean_uses_baked_textures_without_generating() -> void:
	assert_eq(Ocean.foam_noise(), Ocean.FOAM_NOISE)
	assert_eq(Ocean._normal_map(0), Ocean.NORMAL_A)
	assert_eq(Ocean._normal_map(1), Ocean.NORMAL_B)
	assert_ne(Ocean.NORMAL_A.get_class(), "NoiseTexture2D", "ảnh dựng sẵn, không phải NoiseTexture2D sinh lúc chạy")


func test_normal_maps_are_not_flat() -> void:
	# Normal map dựng sẵn phải có độ gợn (không phải ảnh phẳng như bản giữ chỗ).
	var image: Image = Ocean.NORMAL_A.get_image()
	var low: float = 1.0
	var high: float = 0.0
	for x: int in range(0, image.get_width(), 8):
		for y: int in range(0, image.get_height(), 8):
			var c: Color = image.get_pixel(x, y)
			low = minf(low, c.r)
			high = maxf(high, c.r)
	assert_gt(high - low, 0.05)


func test_battle_ready_time_is_measured_from_creation() -> void:
	var battle: BattleController = load("res://battle/battle.tscn").instantiate()
	add_child_autofree(battle)
	await get_tree().process_frame
	assert_gt(battle.ready_msec, 0)
	assert_lt(battle.ready_msec, 20000, "tính từ lúc dựng trận, không tính từ lúc mở game")
