extends GutTest
## Mô hình dựng bằng Blender (tools/blender, xuất ra assets/models/*.glb): đúng trục, đúng cỡ, có màu đỉnh, gọn tam giác.

const ENEMY_PATHS: Dictionary[StringName, String] = {
	&"raider_skiff": "res://data/enemies/raider_skiff.tres",
}
const MAX_ENEMY_TRIANGLES: int = 600


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
		assert_lte(vertices.size() / 3, MAX_ENEMY_TRIANGLES, "%s: ngân sách tam giác" % id)
		assert_eq((arrays[Mesh.ARRAY_COLOR] as PackedColorArray).size(), vertices.size(), "%s: màu đỉnh" % id)
		var box: AABB = mesh.get_aabb()
		var length: float = data.size_cells * MapLayout.UNITS_PER_CELL
		assert_between(box.size.z, length * 0.85, length * 1.25, "%s: dài đúng cỡ" % id)
		assert_between(box.position.y, -0.3, 0.1, "%s: gốc ở mực nước" % id)
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
