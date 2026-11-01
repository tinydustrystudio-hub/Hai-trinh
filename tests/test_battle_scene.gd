extends GutTest
## Cảnh trận dựng đúng từ MapLayout: nước, 10 bệ, 3 luồng, camera; chạm bệ thì chọn bệ.

const BATTLE_SCENE: PackedScene = preload("res://battle/battle.tscn")

var _battle: BattleController


func before_each() -> void:
	_battle = add_child_autofree(BATTLE_SCENE.instantiate())


func test_builds_pads_and_lanes() -> void:
	assert_eq(_battle.island.pads.size(), 14)
	assert_eq(_battle.lanes.size(), 4)
	for lane: Lane in _battle.lanes:
		assert_gt(lane.length(), 40.0)


func test_camera_starts_at_layout_start() -> void:
	assert_eq(_battle.camera.focus, _battle.layout.camera_start)


func test_pad_near_point() -> void:
	var pad_position: Vector3 = _battle.layout.pad_positions[3]
	var pad: TowerPad = _battle.island.pad_near(pad_position + Vector3(1, 0, 0), TowerPad.RADIUS)
	assert_not_null(pad)
	assert_eq(pad.pad_index, 3)
	assert_null(_battle.island.pad_near(Vector3(0, 0, -70), TowerPad.RADIUS))


func test_select_pad_toggles_highlight() -> void:
	var a: TowerPad = _battle.island.pads[0]
	var b: TowerPad = _battle.island.pads[1]
	_battle.select_pad(a)
	assert_true(a.selected)
	_battle.select_pad(b)
	assert_false(a.selected)
	assert_true(b.selected)
	_battle.select_pad(null)
	assert_false(b.selected)


func test_ocean_quality_levels() -> void:
	var ocean: Ocean = _battle.ocean
	ocean.set_quality(Ocean.Quality.LOW)
	assert_eq(ocean.wave_count(), 3)
	assert_eq((ocean.mesh as PlaneMesh).subdivide_width, 95)
	ocean.set_quality(Ocean.Quality.HIGH)
	assert_eq(ocean.wave_count(), 6)
	assert_eq((ocean.mesh as PlaneMesh).subdivide_width, 191)
