extends GutTest
## Hình khối lô cốt và địch: không rỗng, nằm trong khung hợp lý, ba loại địch có bóng khác nhau.

func _enemies() -> Array[EnemyData]:
	var result: Array[EnemyData] = []
	for path: String in ["res://data/enemies/raider_skiff.tres", "res://data/enemies/ram_drone.tres", "res://data/enemies/spiked_crab.tres"]:
		if ResourceLoader.exists(path):
			result.append(load(path) as EnemyData)
	return result


func test_enemy_meshes_have_geometry() -> void:
	var list: Array[EnemyData] = _enemies()
	assert_eq(list.size(), 3)
	for data: EnemyData in list:
		var mesh: ArrayMesh = EnemyMeshes.build(data)
		var box: AABB = mesh.get_aabb()
		assert_gt(box.size.y, 0.8, "địch cần cao đủ để nhìn thấy")
		assert_lt(box.size.x, data.size_cells * MapLayout.UNITS_PER_CELL * 1.6)


func test_enemy_silhouettes_differ() -> void:
	var sizes: Array[Vector3] = []
	for data: EnemyData in _enemies():
		sizes.append(EnemyMeshes.build(data).get_aabb().size)
	assert_eq(sizes.size(), 3)
	assert_ne(sizes[0], sizes[1])
	assert_ne(sizes[1], sizes[2])


func test_tower_meshes_fit_pad() -> void:
	for id: String in ["machine_gun", "glue_sprayer", "light_beam"]:
		var path: String = "res://data/towers/%s.tres" % id
		var data: TowerData = load(path) as TowerData
		assert_not_null(data, path)
		var turret: AABB = TowerMeshes.turret_mesh(data).get_aabb()
		assert_gt(turret.size.z, 1.0, id)
		assert_lt(turret.position.z, -1.0, "nòng phải hướng về −z: %s" % id)
		assert_lt(absf(turret.size.x), 2.6, id)
		var base: AABB = TowerMeshes.base_mesh(data).get_aabb()
		assert_lt(base.size.x, 3.0, id)
