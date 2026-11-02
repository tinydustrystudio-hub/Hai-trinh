extends GutTest
## Kéo lô cốt bằng đúng chuỗi sự kiện chạm như trên điện thoại (không gọi thẳng hàm của trận).

const MACHINE_GUN: TowerData = preload("res://data/towers/machine_gun.tres")


func before_each() -> void:
	Profile.reset_to_new()


func after_all() -> void:
	Profile.reset_to_new()


func _touch(index: int, position: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	return event


func _drag(index: int, position: Vector2) -> InputEventScreenDrag:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.index = index
	event.position = position
	return event


func test_dragging_a_tower_with_real_touch_events_moves_it() -> void:
	var battle: BattleController = load("res://battle/battle.tscn").instantiate()
	add_child_autofree(battle)
	await get_tree().process_frame
	var from: TowerPad = battle.island.pads[0]
	var to: TowerPad = battle.island.pads[2]
	var tower: Tower = battle.build_tower(from, MACHINE_GUN)
	assert_gte(battle.economy.steel, Profile.tower_move_cost(), "đủ vàng để dời")
	var start: Vector2 = battle.camera.unproject_position(from.global_position + Vector3(0, 1.5, 0))
	var finish: Vector2 = battle.camera.unproject_position(to.global_position + Vector3(0, 0.7, 0))
	var input: TouchInput = battle.touch_input
	input.handle_event(_touch(0, start, true))
	for step: int in range(1, 11):
		input.handle_event(_drag(0, start.lerp(finish, float(step) / 10.0)))
	assert_true(battle.tower_dragging, "đang kéo lô cốt")
	assert_eq(battle.move_target, to, "bệ đích hút lô cốt")
	input.handle_event(_touch(0, finish, false))
	assert_false(battle.tower_dragging)
	assert_eq(battle.moving_tower, tower, "chờ xác nhận")
	assert_true(battle.move_confirm.confirm_button().visible, "hiện dấu tích")
	assert_false(battle.move_confirm.confirm_button().disabled)
	battle.move_confirm.confirm_button().pressed.emit()
	assert_eq(tower.pad, to, "lô cốt đã sang bệ mới")
	assert_true(to.occupied)
	assert_false(from.occupied)


func test_target_pad_snaps_from_a_generous_distance_and_grab_is_forgiving() -> void:
	var battle: BattleController = load("res://battle/battle.tscn").instantiate()
	add_child_autofree(battle)
	await get_tree().process_frame
	var from: TowerPad = battle.island.pads[0]
	var to: TowerPad = battle.island.pads[2]
	var tower: Tower = battle.build_tower(from, MACHINE_GUN)
	# Chạm lệch khỏi tâm bệ chừng 3 đơn vị vẫn bắt được lô cốt.
	var off_grab: Vector3 = from.global_position + Vector3(2.2, 0.7, 2.2)
	assert_true(battle.begin_tower_drag(battle.camera.unproject_position(off_grab)), "bắt lô cốt khi chạm lệch")
	# Ngón tay còn cách bệ đích ~5 đơn vị: vẫn hút vào bệ trống gần nhất.
	var near_target: Vector3 = to.global_position + Vector3(3.5, 0.7, 3.5)
	battle.drag_tower_to(battle.camera.unproject_position(near_target))
	assert_eq(battle.move_target, to, "bệ trống gần ngón tay nhất hút lô cốt")
	# Ngón tay ra xa mọi bệ trống thì không hút.
	battle.drag_tower_to(Vector2(30, 30))
	assert_null(battle.move_target)
	battle.cancel_move()
	assert_eq(tower.pad, from)
