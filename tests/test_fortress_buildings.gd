extends GutTest
## Công trình theo cấp trên đảo chính và tiện ích trên đảo vệ tinh.

const LAYOUT_PATH: String = "res://data/maps/north_dock_layout.tres"


func _layout(levels: Dictionary[StringName, int] = {}) -> MapLayout:
	var layout: MapLayout = (load(LAYOUT_PATH) as MapLayout).duplicate() as MapLayout
	layout.building_levels = levels
	return layout


func _triangles(mesh: ArrayMesh) -> int:
	return mesh.surface_get_array_len(0) / 3


## Số tam giác của công trình id ở cấp level: mô hình Blender nếu có, không thì cả thân đảo dựng bằng code.
func _building_triangles(id: StringName, level: int) -> int:
	if AllianceFortress.has_building_model(id, level):
		return _triangles(ModelMesh.load_mesh(AllianceFortress.building_model_name(id, level)))
	return _triangles(AllianceFortress.build_fortress(_layout({id: level})))


func test_default_level_is_one() -> void:
	assert_eq(_layout().building_level(&"wave_shield"), 1)
	assert_eq(_layout({&"shipyard": 9}).building_level(&"shipyard"), 5)


func test_wall_grows_with_level_and_docks_grow() -> void:
	assert_almost_eq(AllianceFortress.wall_height(1), 1.1, 0.001)
	assert_gt(AllianceFortress.wall_height(5), AllianceFortress.wall_height(3))
	assert_gt(AllianceFortress.wall_thickness_scale(5), AllianceFortress.wall_thickness_scale(1))
	assert_eq(FortressBuildings.shipyard_docks(3), 1)
	assert_eq(FortressBuildings.shipyard_docks(5), 2)


func test_higher_levels_add_geometry() -> void:
	var total: Callable = func(level: int) -> int:
		var sum: int = _triangles(AllianceFortress.build_fortress(_layout({&"wave_shield": level, &"repair_works": level, &"shipyard": level})))
		for id: StringName in [&"wave_shield", &"repair_works", &"shipyard"]:
			if AllianceFortress.has_building_model(id, level):
				sum += _triangles(ModelMesh.load_mesh(AllianceFortress.building_model_name(id, level)))
		return sum
	var low: int = total.call(1)
	var mid: int = total.call(3)
	var high: int = total.call(5)
	assert_gt(mid, low)
	assert_gt(high, mid)
	assert_lt(high, 20000, "ngân sách tam giác của đảo chính")


func test_every_utility_builds_distinct_mesh() -> void:
	var counts: Array[int] = []
	for id: StringName in SatelliteUtilities.IDS:
		var st: SurfaceTool = MeshKit.begin()
		SatelliteUtilities.build(st, id, Vector3.ZERO, Vector3.RIGHT)
		var mesh: ArrayMesh = st.commit()
		assert_gt(mesh.get_aabb().size.y, 1.0, String(id))
		counts.append(_triangles(mesh))
	assert_eq(counts.size(), 4)


func test_utility_stays_clear_of_pad_and_island_edge() -> void:
	for id: StringName in SatelliteUtilities.IDS:
		var st: SurfaceTool = MeshKit.begin()
		SatelliteUtilities.build(st, id, Vector3.ZERO, Vector3.RIGHT)
		var box: AABB = st.commit().get_aabb()
		assert_gt(box.position.x, 1.3, "không đè bệ lô cốt: %s" % id)
		assert_lt(box.end.x, 3.9, "nằm trong đảo: %s" % id)


func test_layout_cycles_utilities() -> void:
	var layout: MapLayout = _layout()
	assert_eq(layout.satellite_utility(0), &"radar_outpost")
	assert_eq(layout.satellite_utility(5), &"steel_depot")
	layout.satellite_utilities = [&"comms_tower"]
	assert_eq(layout.satellite_utility(0), &"comms_tower")


func test_tidal_power_levels_add_turbine_and_battery() -> void:
	var l1: int = _building_triangles(&"tidal_power", 1)
	var l3: int = _building_triangles(&"tidal_power", 3)
	var l5: int = _building_triangles(&"tidal_power", 5)
	assert_gt(l3, l1)
	assert_gt(l5, l3)


## Số tam giác của công trình id ở cấp level: mô hình Blender nếu có, không thì cả thân đảo dựng bằng code.
func _building_triangles(id: StringName, level: int) -> int:
	if AllianceFortress.has_building_model(id, level):
		return _triangles(ModelMesh.load_mesh(AllianceFortress.building_model_name(id, level)))
	return _triangles(AllianceFortress.build_fortress(_layout({id: level})))


func test_every_level_changes_every_building() -> void:
	for id: StringName in [&"wave_shield", &"repair_works", &"tidal_power", &"shipyard"]:
		var previous: int = _building_triangles(id, 1)
		for level: int in range(2, 6):
			var current: int = _building_triangles(id, level)
			assert_gt(current, previous, "%s cấp %d phải thấy khác cấp %d" % [id, level, level - 1])
			previous = current


func test_wave_wall_upgrade_shows_on_every_side_of_the_island() -> void:
	# Cấp 3: tháp góc cao ở cả sáu góc quanh đảo (không chỉ một góc), dù là mô hình Blender hay bản dựng bằng code.
	var layout: MapLayout = _layout({&"wave_shield": 3})
	var mesh: ArrayMesh
	var origin: Vector3 = layout.fortress_center
	if AllianceFortress.has_building_model(&"wave_shield", 3):
		mesh = ModelMesh.load_mesh(AllianceFortress.building_model_name(&"wave_shield", 3))
		origin = Vector3.ZERO
	else:
		mesh = AllianceFortress.build_fortress(layout)
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var sectors: Dictionary = {}
	for v: Vector3 in vertices:
		var flat: Vector2 = Vector2(v.x - origin.x, v.z - origin.z)
		if v.y > AllianceFortress.DECK_Y + 2.0 and flat.length() > layout.fortress_radius * 0.8:
			sectors[int(floorf(fposmod(rad_to_deg(flat.angle()) + 30.0, 360.0) / 60.0))] = true
	assert_eq(sectors.size(), 6, "tháp góc cao ở đủ sáu góc")
	assert_gt(_building_triangles(&"wave_shield", 3), _building_triangles(&"wave_shield", 1))


func test_tidal_cable_lines_span_the_island() -> void:
	var plain: int = _building_triangles(&"tidal_power", 1)
	var lines: int = _building_triangles(&"tidal_power", 2)
	assert_gt(lines - plain, 6 * 12, "ống cáp ở cả sáu cạnh")
