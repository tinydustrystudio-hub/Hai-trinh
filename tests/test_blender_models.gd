extends GutTest
## Mô hình dựng bằng Blender (tools/blender, xuất ra assets/models/*.glb): đúng trục, đúng cỡ, có màu đỉnh, gọn tam giác.

const ENEMY_PATHS: Dictionary[StringName, String] = {
	&"raider_skiff": "res://data/enemies/raider_skiff.tres",
	&"ram_drone": "res://data/enemies/ram_drone.tres",
	&"spiked_crab": "res://data/enemies/spiked_crab.tres",
}
## Ngân sách tam giác mỗi loại địch (tối đa 60 địch cùng lúc; Cua Giáp Gai hiếm và lớn nên được nhiều hơn).
const MAX_ENEMY_TRIANGLES: Dictionary[StringName, int] = {
	&"raider_skiff": 700,
	&"ram_drone": 900,
	&"spiked_crab": 1600,
}


func test_enemy_models_load_and_are_used_by_the_game() -> void:
	for id: StringName in ENEMY_PATHS:
		var data: EnemyData = load(ENEMY_PATHS[id]) as EnemyData
		var model: ArrayMesh = EnemyMeshes.model_mesh(data)
		assert_not_null(model, "thiếu mô hình cho %s" % id)
		assert_eq(EnemyMeshes.mesh_for(data), EnemyMeshes.mesh_for(data), "dùng chung một mesh")
		assert_eq(EnemyMeshes.mesh_for(data).get_aabb(), model.get_aabb(), "game dùng mô hình Blender, không dựng bằng code")


func test_enemy_models_have_correct_size_axis_and_budget() -> void:
	for id: StringName in ENEMY_PATHS:
		var data: EnemyData = load(ENEMY_PATHS[id]) as EnemyData
		var mesh: ArrayMesh = EnemyMeshes.model_mesh(data)
		var arrays: Array = mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		assert_lte(vertices.size() / 3, MAX_ENEMY_TRIANGLES[id], "%s: ngân sách tam giác" % id)
		assert_eq((arrays[Mesh.ARRAY_COLOR] as PackedColorArray).size(), vertices.size(), "%s: màu đỉnh" % id)
		var box: AABB = mesh.get_aabb()
		var length: float = data.size_cells * MapLayout.UNITS_PER_CELL
		assert_between(box.size.z, length * 0.85, length * 1.25, "%s: dài đúng cỡ" % id)
		assert_between(box.position.y, -0.5, 0.2, "%s: đáy gần mực nước" % id)
		if data.hull == EnemyData.Hull.CRAB:
			# Cua: hai càng giơ ra phía trước (−z) ở hai bên, thân đối xứng trái phải.
			var front_x: float = 0.0
			var min_z_crab: float = INF
			for v: Vector3 in vertices:
				if v.z < min_z_crab:
					min_z_crab = v.z
					front_x = absf(v.x)
			assert_gt(front_x, 1.0, "%s: càng ở hai bên phía trước" % id)
			assert_almost_eq(box.position.x, -box.end.x, 0.3, "%s: đối xứng trái phải" % id)
			continue
		# Mũi tàu hướng −z: đỉnh nhô xa nhất về −z nằm gần trục giữa; đuôi (+z) rộng hơn mũi.
		var bow_x: float = 0.0
		var min_z: float = INF
		for v: Vector3 in vertices:
			if v.z < min_z:
				min_z = v.z
				bow_x = v.x
		assert_lt(absf(bow_x), 0.25, "%s: mũi ở giữa" % id)
		var bow_half: float = 0.0
		var stern_half: float = 0.0
		for v: Vector3 in vertices:
			if v.z < box.position.z + box.size.z * 0.2:
				bow_half = maxf(bow_half, absf(v.x))
			if v.z > box.position.z + box.size.z * 0.8:
				stern_half = maxf(stern_half, absf(v.x))
		assert_lt(bow_half, stern_half, "%s: mũi thon hơn đuôi (mũi hướng −z)" % id)


func test_models_use_the_shared_vertex_color_material() -> void:
	assert_true(EnemyMeshes.material().vertex_color_use_as_albedo)


const TOWER_PATHS: Dictionary[StringName, String] = {
	&"machine_gun": "res://data/towers/machine_gun.tres",
	&"glue_sprayer": "res://data/towers/glue_sprayer.tres",
	&"light_beam": "res://data/towers/light_beam.tres",
}
const MAX_TOWER_TRIANGLES: int = 2000


func test_tower_models_are_used_by_the_game() -> void:
	for id: StringName in TOWER_PATHS:
		var data: TowerData = load(TOWER_PATHS[id]) as TowerData
		assert_true(ModelMesh.exists("twr_%s_base" % id), "thiếu đế %s" % id)
		assert_true(ModelMesh.exists("twr_%s_turret" % id), "thiếu đầu nòng %s" % id)
		assert_eq(TowerMeshes.base_mesh(data).get_aabb(), ModelMesh.load_mesh("twr_%s_base" % id).get_aabb(), "game dùng đế Blender")
		assert_eq(TowerMeshes.turret_mesh(data).get_aabb(), ModelMesh.load_mesh("twr_%s_turret" % id).get_aabb(), "game dùng đầu nòng Blender")


func test_tower_models_fit_pad_axis_and_budget() -> void:
	for id: StringName in TOWER_PATHS:
		var data: TowerData = load(TOWER_PATHS[id]) as TowerData
		var base: ArrayMesh = TowerMeshes.base_mesh(data)
		var turret: ArrayMesh = TowerMeshes.turret_mesh(data)
		var triangles: int = (base.surface_get_array_len(0) + turret.surface_get_array_len(0)) / 3
		assert_lte(triangles, MAX_TOWER_TRIANGLES, "%s: ngân sách tam giác" % id)
		var base_box: AABB = base.get_aabb()
		assert_between(base_box.size.x, 2.2, 2.8, "%s: đế vừa bệ (lục giác bán kính 1,25)" % id)
		assert_almost_eq(base_box.position.y, TowerPad.TOP_HEIGHT, 0.05, "%s: đế đặt trên mặt bệ" % id)
		assert_between(base_box.end.y, 1.75, 2.0, "%s: cột cao tới chỗ đầu nòng tựa" % id)
		var head_box: AABB = turret.get_aabb()
		# Nòng hướng −z và đầu nòng cách trục xấp xỉ BARREL_LENGTH.
		assert_between(head_box.position.z, -TowerMeshes.BARREL_LENGTH - 0.15, -TowerMeshes.BARREL_LENGTH + 0.3, "%s: miệng nòng ở −z" % id)
		assert_gt(head_box.end.z, 0.2, "%s: thân đầu nòng ở phía sau trục" % id)
		assert_lt(head_box.size.x, 2.2, "%s: đầu nòng không rộng hơn đế" % id)


func test_wave_wall_models_exist_for_every_level_and_grow() -> void:
	var previous_height: float = 0.0
	var previous_triangles: int = 0
	for level: int in range(1, 6):
		var name: String = AllianceFortress.building_model_name(&"wave_shield", level)
		var mesh: ArrayMesh = ModelMesh.load_mesh(name)
		assert_not_null(mesh, "thiếu %s" % name)
		var box: AABB = mesh.get_aabb()
		# Tường bao cả đảo: cùng cỡ lục giác bán kính 14, tâm ở gốc.
		assert_between(box.size.x, 26.0, 30.0, "%s: bao cả đảo" % name)
		assert_almost_eq(box.position.x, -box.end.x, 0.8, "%s: đối xứng quanh tâm" % name)
		assert_gt(box.end.y, previous_height, "%s: cao hơn cấp trước" % name)
		var triangles: int = mesh.surface_get_array_len(0) / 3
		assert_gt(triangles, previous_triangles, "%s: nhiều chi tiết hơn cấp trước" % name)
		assert_lt(triangles, 6000, "%s: ngân sách tam giác" % name)
		previous_height = box.end.y
		previous_triangles = triangles


func test_island_uses_wave_wall_model_and_skips_code_wall() -> void:
	var layout: MapLayout = (load("res://data/maps/north_dock_layout.tres") as MapLayout).duplicate() as MapLayout
	layout.building_levels = {&"wave_shield": 3}
	var island: Island = Island.new()
	add_child_autofree(island)
	island.build(layout)
	var node: MeshInstance3D = island.get_node("Body/Building_wave_shield") as MeshInstance3D
	assert_not_null(node, "đảo thêm mô hình Tường Chắn Sóng")
	assert_eq(node.mesh, ModelMesh.load_mesh("bld_wave_shield_l3"))
	assert_true(AllianceFortress.has_building_model(&"wave_shield", 3))
	# Khi có mô hình, bản dựng bằng code không dựng thêm tường: thân đảo ít tam giác hơn bản không có mô hình.
	var with_model: int = AllianceFortress.build_fortress(layout).surface_get_array_len(0)
	assert_lt(with_model, 20000)


func test_satellite_utility_models_fit_the_island() -> void:
	for id: StringName in SatelliteUtilities.IDS:
		var mesh: ArrayMesh = ModelMesh.load_mesh(SatelliteUtilities.model_name(id))
		assert_not_null(mesh, "thiếu mô hình %s" % id)
		var box: AABB = mesh.get_aabb()
		# Gốc ở chỗ đặt tiện ích (cách tâm đảo OFFSET), +x ra ngoài: không đè bệ ở tâm và nằm trong đảo bán kính 4.
		assert_gt(box.position.x + SatelliteUtilities.OFFSET, 1.3, "%s: không đè bệ lô cốt" % id)
		assert_lt(box.end.x + SatelliteUtilities.OFFSET, 3.95, "%s: nằm trong đảo" % id)
		assert_between(absf(box.position.z), 0.0, 1.5, "%s: lệch bên vừa phải" % id)
		assert_between(box.end.y, 1.0, 6.0, "%s: có chiều cao nhận ra khi thu nhỏ" % id)
		assert_lt(mesh.surface_get_array_len(0) / 3, 1500, "%s: ngân sách tam giác" % id)


func test_island_adds_utility_model_to_each_satellite() -> void:
	var layout: MapLayout = TestLayouts.with_satellites(4)
	var island: Island = Island.new()
	add_child_autofree(island)
	island.build(layout)
	assert_eq(island.satellites.size(), 4)
	for k: int in 4:
		var utility: MeshInstance3D = island.satellites[k].get_node_or_null("Utility") as MeshInstance3D
		assert_not_null(utility, "đảo %d thiếu tiện ích" % k)
		assert_eq(utility.mesh, ModelMesh.load_mesh(SatelliteUtilities.model_name(layout.satellite_utility(k))))
		# Mô hình quay mặt ra phía ngoài đảo chính (+x của mô hình trùng hướng tiện ích).
		var direction: Vector3 = SatelliteUtilities.direction_for(layout, k)
		assert_almost_eq((utility.transform.basis * Vector3.RIGHT).dot(direction), 1.0, 0.001)
