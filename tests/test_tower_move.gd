extends GutTest
## Dời lô cốt sang bệ trống khác: tốn phí bằng giá lô cốt rẻ nhất, lô cốt giữ nguyên cấp và Quá tải.

const MACHINE_GUN: TowerData = preload("res://data/towers/machine_gun.tres")
const GLUE: TowerData = preload("res://data/towers/glue_sprayer.tres")


func before_each() -> void:
	Profile.reset_to_new()


func after_all() -> void:
	Profile.reset_to_new()


func _new_battle() -> BattleController:
	var battle: BattleController = load("res://battle/battle.tscn").instantiate()
	add_child_autofree(battle)
	await get_tree().process_frame
	battle.economy.reset(5000)
	return battle


func test_move_cost_equals_cheapest_tower() -> void:
	assert_eq(Profile.tower_move_cost(), Profile.cheapest_tower_cost())
	assert_eq(Profile.economy_rules.tower_move_cost(61), 61)


func test_move_keeps_level_branch_and_pays_cost() -> void:
	var battle: BattleController = await _new_battle()
	var from: TowerPad = battle.island.pads[0]
	var to: TowerPad = battle.island.pads[1]
	var tower: Tower = battle.build_tower(from, MACHINE_GUN)
	battle.upgrade_tower(tower)
	var invested: int = tower.invested
	var before: int = battle.economy.steel
	assert_true(battle.move_tower(tower, to))
	assert_eq(battle.economy.steel, before - Profile.tower_move_cost())
	assert_eq(tower.pad, to)
	assert_eq(tower.get_parent(), to)
	assert_true(to.occupied)
	assert_false(from.occupied)
	assert_eq(tower.level, 2)
	assert_eq(tower.invested, invested, "dời không đổi tổng Thép đã bỏ vào")
	assert_eq(battle.tower_on(to), tower)
	assert_null(battle.tower_on(from))
	assert_eq(tower.position, Vector3.ZERO)


func test_cannot_move_to_occupied_locked_or_without_gold() -> void:
	Profile.set_gold(100000)
	Profile.buy_island()
	var battle: BattleController = await _new_battle()
	var tower: Tower = battle.build_tower(battle.island.pads[0], MACHINE_GUN)
	battle.build_tower(battle.island.pads[1], MACHINE_GUN)
	assert_false(battle.move_tower(tower, battle.island.pads[1]), "bệ có lô cốt")
	assert_false(battle.move_tower(tower, battle.island.pads[battle.island.pads.size() - 1]), "bệ của đảo còn đậu bị khoá")
	assert_false(battle.move_tower(tower, tower.pad), "cùng bệ")
	battle.economy.reset(Profile.tower_move_cost() - 1)
	assert_false(battle.move_tower(tower, battle.island.pads[2]), "thiếu vàng")
	assert_eq(battle.economy.steel, Profile.tower_move_cost() - 1)


func _screen(battle: BattleController, pad: TowerPad) -> Vector2:
	return battle.camera.unproject_position(pad.global_position)


func test_drag_tower_to_empty_pad_needs_confirmation() -> void:
	var battle: BattleController = await _new_battle()
	var from: TowerPad = battle.island.pads[0]
	var target: TowerPad = battle.island.pads[2]
	var tower: Tower = battle.build_tower(from, MACHINE_GUN)
	var before: int = battle.economy.steel
	assert_true(battle.begin_tower_drag(_screen(battle, from)))
	assert_true(tower.carried)
	assert_true(battle.tower_dragging)
	battle.drag_tower_to(_screen(battle, target))
	assert_eq(battle.move_target, target)
	assert_gt(target.range_shown(), 0.0, "hiện tầm bắn tại bệ đích")
	assert_almost_eq(tower.global_position.x, target.global_position.x, 0.01, "lô cốt đi theo ngón tay, hút vào bệ")
	battle.end_tower_drag()
	assert_true(battle.move_confirm.confirm_button().visible)
	assert_eq(battle.economy.steel, before, "chưa xác nhận thì chưa tốn vàng")
	assert_eq(tower.pad, from)
	assert_true(battle.confirm_move())
	assert_eq(tower.pad, target)
	assert_false(tower.carried)
	assert_eq(tower.position, Vector3.ZERO)
	assert_null(battle.moving_tower)
	assert_eq(battle.economy.steel, before - Profile.tower_move_cost())


func test_drop_away_from_pads_returns_tower_free() -> void:
	var battle: BattleController = await _new_battle()
	var from: TowerPad = battle.island.pads[0]
	var tower: Tower = battle.build_tower(from, MACHINE_GUN)
	var before: int = battle.economy.steel
	battle.begin_tower_drag(_screen(battle, from))
	battle.drag_tower_to(Vector2(40, 40))
	assert_null(battle.move_target)
	battle.end_tower_drag()
	assert_false(tower.carried)
	assert_eq(tower.pad, from)
	assert_eq(tower.position, Vector3.ZERO, "về lại bệ cũ")
	assert_eq(battle.economy.steel, before)
	assert_null(battle.moving_tower)


func test_cancel_after_drop_keeps_tower_and_gold() -> void:
	var battle: BattleController = await _new_battle()
	var from: TowerPad = battle.island.pads[0]
	var tower: Tower = battle.build_tower(from, MACHINE_GUN)
	var before: int = battle.economy.steel
	battle.begin_tower_drag(_screen(battle, from))
	battle.drag_tower_to(_screen(battle, battle.island.pads[2]))
	battle.end_tower_drag()
	battle.cancel_move()
	assert_eq(tower.pad, from)
	assert_eq(tower.position, Vector3.ZERO)
	assert_eq(battle.economy.steel, before)
	assert_eq(battle.island.pads[2].range_shown(), 0.0)
	assert_false(tower.carried)


func test_cannot_drag_onto_occupied_pad_and_empty_pad_is_not_draggable() -> void:
	var battle: BattleController = await _new_battle()
	var a: Tower = battle.build_tower(battle.island.pads[0], MACHINE_GUN)
	battle.build_tower(battle.island.pads[1], MACHINE_GUN)
	assert_false(battle.begin_tower_drag(_screen(battle, battle.island.pads[3])), "bệ trống không kéo được")
	assert_true(battle.begin_tower_drag(_screen(battle, battle.island.pads[0])))
	battle.drag_tower_to(_screen(battle, battle.island.pads[1]))
	assert_null(battle.move_target, "bệ có lô cốt không nhận")
	battle.end_tower_drag()
	assert_eq(a.pad, battle.island.pads[0])


func test_carried_tower_does_not_fire() -> void:
	var battle: BattleController = await _new_battle()
	var tower: Tower = battle.build_tower(battle.island.pads[0], MACHINE_GUN)
	battle.begin_tower_drag(_screen(battle, battle.island.pads[0]))
	tower.tick(1.0)
	assert_eq(tower.target, null)
	battle.cancel_move()
	assert_false(tower.carried)


func test_glue_tower_relocates_its_lake() -> void:
	var battle: BattleController = await _new_battle()
	var tower: Tower = battle.build_tower(battle.island.pads[0], GLUE)
	assert_true(battle.move_tower(tower, battle.island.pads[3]))
	assert_eq(tower.pad, battle.island.pads[3])


func test_tower_cannot_be_lifted_without_gold() -> void:
	var battle: BattleController = await _new_battle()
	var from: TowerPad = battle.island.pads[0]
	var tower: Tower = battle.build_tower(from, MACHINE_GUN)
	battle.economy.reset(Profile.tower_move_cost() - 1)
	assert_true(battle.begin_tower_drag(_screen(battle, from)), "cử chỉ được xử lý (không kéo camera)")
	assert_false(battle.tower_dragging, "nhưng lô cốt không rời bệ")
	assert_false(tower.carried)
	assert_null(battle.moving_tower)
	assert_true(battle.move_confirm.is_flashing(), "báo thiếu vàng")
	assert_false(battle.move_tower(tower, battle.island.pads[2]))
	assert_eq(tower.pad, from)
	assert_eq(battle.economy.steel, Profile.tower_move_cost() - 1)
