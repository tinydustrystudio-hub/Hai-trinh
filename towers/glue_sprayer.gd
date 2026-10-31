class_name GlueSprayer
extends Tower
## Lô Cốt Keo (GDD mục 3.4): mỗi lần phun (tốc bắn 2, tức mỗi 0,5 giây) đặt một vũng keo bán kính
## glue_radius tại chỗ mục tiêu. Địch ở trong vũng keo của lô cốt này bị chậm slow_amount (làm mới
## slow_duration giây) và mất damage_per_second máu mỗi giây. Vũng keo tồn tại slow_duration giây.
## Nhánh 5A Hồ Keo: một hồ keo cố định trên đoạn luồng gần nhất trong tầm, không phun nữa; kỹ năng Dính Chặt
## cứ 10 giây giữ đứng yên 1,5 giây mọi địch trong hồ (trùm, tàu tinh nhuệ chỉ chậm thêm 20%).
## Nhánh 5B Keo Ăn Mòn: mỗi lần phun trúng giảm 2 bậc giáp trong 4 giây; kỹ năng Bóc Giáp: trúng 3 lần phun
## liên tiếp thì mất toàn bộ giáp trong 3 giây.

## Số vũng keo của một lô cốt cùng lúc (đủ cho 2 giây ở nhịp phun 0,5 giây).
const MAX_PUDDLES: int = 4

## Số địch đang bị chính lô cốt này làm chậm (để nạp Quá tải).
var slowed_count: int = 0
var sprays: int = 0
var holds: int = 0
## Tâm hồ keo của nhánh Hồ Keo.
var lake_center: Vector3 = Vector3.ZERO

var _puddles: GluePuddles
var _cooldown: float = 0.0
var _puddle_positions: PackedVector3Array = PackedVector3Array()
var _puddle_life: PackedFloat32Array = PackedFloat32Array()
var _next_puddle: int = 0
var _hold_left: float = 0.0


func _setup_effects(effects: Node) -> void:
	_puddles = effects.get_node_or_null("GluePuddles") as GluePuddles if effects != null else null
	_puddle_positions.resize(MAX_PUDDLES)
	_puddle_life.resize(MAX_PUDDLES)
	_puddle_life.fill(0.0)


func _on_branch_chosen(lanes: Array[Lane]) -> void:
	if not branch.fixed_lake:
		return
	lake_center = lake_anchor(global_position, lanes, range_units())
	_puddle_life.fill(0.0)
	_puddle_positions[0] = lake_center
	_puddle_life[0] = stats().slow_duration
	_hold_left = branch.hold_interval


## Chỗ đặt hồ keo: điểm gần lô cốt nhất trên các luồng, nếu trong tầm; không có thì ngay dưới lô cốt.
static func lake_anchor(origin: Vector3, lanes: Array[Lane], reach: float) -> Vector3:
	var best: Vector3 = Vector3(origin.x, 0.0, origin.z)
	var best_distance: float = INF
	for lane: Lane in lanes:
		var local: Vector3 = origin - lane.global_position if lane.is_inside_tree() else origin - lane.position
		var point: Vector3 = lane.to_global_safe(lane.curve.get_closest_point(local))
		var distance: float = Vector2(point.x - origin.x, point.z - origin.z).length()
		if distance < best_distance and distance <= reach:
			best = Vector3(point.x, 0.0, point.z)
			best_distance = distance
	return best


func has_lake() -> bool:
	return branch != null and branch.fixed_lake


func fire(delta: float) -> void:
	for i: int in MAX_PUDDLES:
		if _puddle_life[i] > 0.0:
			_puddle_life[i] = maxf(_puddle_life[i] - delta, 0.0)
	if has_lake():
		# Hồ keo không bao giờ cạn; không phun thêm.
		_puddle_life[0] = stats().slow_duration
		_update_hold(delta)
		_apply_glue(delta)
		return
	_cooldown -= delta
	if target == null:
		_cooldown = maxf(_cooldown, 0.0)
	else:
		var interval: float = 1.0 / maxf(stats().fire_rate, 0.001)
		while _cooldown <= 0.0:
			_cooldown += interval
			spray(target.global_position)
	_apply_glue(delta)


## Đặt một vũng keo mới tại point (thay vũng cũ nhất). Keo Ăn Mòn ăn giáp những địch trúng lần phun này.
func spray(point: Vector3) -> void:
	sprays += 1
	_puddle_positions[_next_puddle] = Vector3(point.x, 0.0, point.z)
	_puddle_life[_next_puddle] = stats().slow_duration
	_next_puddle = (_next_puddle + 1) % MAX_PUDDLES
	if branch != null and branch.armor_tier_reduction > 0:
		_corrode(point)


## Giữ đứng yên (hoặc làm chậm thêm với trùm và tàu tinh nhuệ) mọi địch đang ở trong hồ.
func hold_lake() -> int:
	holds += 1
	var held: int = 0
	var resistant_source: int = get_instance_id() + 1
	for enemy: Enemy in _pool.active:
		if not data.target_layers.has(enemy.data.layer) or not in_glue(enemy.global_position):
			continue
		if enemy.data.is_boss or enemy.data.is_elite:
			enemy.status.apply_slow(resistant_source, branch.hold_resistant_slow, branch.hold_duration)
		else:
			enemy.status.hold(branch.hold_duration)
		held += 1
	return held


func _update_hold(delta: float) -> void:
	if branch.hold_interval <= 0.0:
		return
	_hold_left -= delta
	if _hold_left <= 0.0:
		_hold_left += branch.hold_interval
		hold_lake()


func _corrode(point: Vector3) -> void:
	var radius_squared: float = glue_radius() * glue_radius()
	var source: int = get_instance_id()
	for enemy: Enemy in _pool.active:
		if not data.target_layers.has(enemy.data.layer):
			continue
		var dx: float = enemy.global_position.x - point.x
		var dz: float = enemy.global_position.z - point.z
		if dx * dx + dz * dz > radius_squared:
			continue
		enemy.status.reduce_armor(branch.armor_tier_reduction, branch.armor_reduction_duration)
		if branch.armor_break_hits > 0 and enemy.status.record_spray_hit(source, sprays) >= branch.armor_break_hits:
			enemy.status.break_armor(branch.armor_break_duration)
			enemy.status.reset_spray_streak()


## Bán kính vùng keo (đơn vị Godot); MEGA nới rộng theo hệ số hỗ trợ (×1,5), làm mát không thu hẹp.
func glue_radius() -> float:
	return stats().glue_radius_cells * MapLayout.UNITS_PER_CELL * maxf(overload_multiplier(), 1.0)


func in_glue(point: Vector3) -> bool:
	var radius_squared: float = glue_radius() * glue_radius()
	for i: int in MAX_PUDDLES:
		if _puddle_life[i] <= 0.0:
			continue
		var dx: float = point.x - _puddle_positions[i].x
		var dz: float = point.z - _puddle_positions[i].z
		if dx * dx + dz * dz <= radius_squared:
			return true
	return false


## Ghi các vũng keo đang có vào bộ vẽ chung.
func draw_puddles(renderer: GluePuddles) -> void:
	var radius: float = glue_radius()
	var duration: float = maxf(stats().slow_duration, 0.001)
	for i: int in MAX_PUDDLES:
		if _puddle_life[i] > 0.0:
			renderer.draw(_puddle_positions[i], radius, _puddle_life[i] / duration)


func _apply_glue(delta: float) -> void:
	var level: TowerLevel = stats()
	var power: float = overload_multiplier()
	var slow: float = level.slow_amount * power
	var source: int = get_instance_id()
	slowed_count = 0
	# Duyệt ngược vì địch bị hạ sẽ rời danh sách.
	for i: int in range(_pool.active.size() - 1, -1, -1):
		var enemy: Enemy = _pool.active[i]
		if not data.target_layers.has(enemy.data.layer) or not in_glue(enemy.global_position):
			continue
		enemy.status.apply_slow(source, slow, level.slow_duration)
		slowed_count += 1
		if level.damage_per_second > 0.0:
			_pool.damage(enemy, level.damage_per_second * power * delta)
	# Nạp Quá tải theo số địch đang dính keo (kế hoạch mục 5.4).
	overload.add_charge(Overload.glue_charge_rate(slowed_count, data.overload_charge_seconds) * delta)
