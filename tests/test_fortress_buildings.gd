extends GutTest
## Công trình theo cấp trên đảo chính và tiện ích trên đảo vệ tinh.

const LAYOUT_PATH: String = "res://data/maps/north_dock_layout.tres"


func _layout(levels: Dictionary[StringName, int] = {}) -> MapLayout:
	var layout: MapLayout = (load(LAYOUT_PATH) as MapLayout).duplicate() as MapLayout
	layout.building_levels = levels
	return layout


func _triangles(mesh: ArrayMesh) -> int:
	return mesh.surface_get_array_len(0) / 3


func test_default_level_is_one() -> void:
	assert_eq(_layout().building_level(&"wave_shield"), 1)
	assert_eq(_layout({&"shipyard": 9}).building_level(&"shipyard"), 5)


func test_shield_posts_and_docks_grow_with_level() -> void:
	assert_eq(FortressBuildings.shield_posts(1), 1)
	assert_eq(FortressBuildings.shield_posts(3), 3)
	assert_eq(FortressBuildings.shield_posts(5), 5)
	assert_eq(FortressBuildings.shipyard_docks(3), 1)
	assert_eq(FortressBuildings.shipyard_docks(5), 2)


func test_higher_levels_add_geometry() -> void:
	var low: int = _triangles(AllianceFortress.build_fortress(_layout()))
	var mid: int = _triangles(AllianceFortress.build_fortress(_layout({&"wave_shield": 3, &"repair_works": 3, &"shipyard": 3})))
	var high: int = _triangles(AllianceFortress.build_fortress(_layout({&"wave_shield": 5, &"repair_works": 5, &"shipyard": 5})))
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
