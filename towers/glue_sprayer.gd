class_name GlueSprayer
extends Tower
## Lô Cốt Keo (GDD mục 3.4): mỗi lần phun (tốc bắn 2, tức mỗi 0,5 giây) đặt một vũng keo bán kính
## glue_radius tại chỗ mục tiêu. Địch ở trong vũng keo của lô cốt này bị chậm slow_amount (làm mới
## slow_duration giây) và mất damage_per_second máu mỗi giây. Vũng keo tồn tại slow_duration giây.

## Số vũng keo của một lô cốt cùng lúc (đủ cho 2 giây ở nhịp phun 0,5 giây).
const MAX_PUDDLES: int = 4

## Hệ số hiệu ứng hiện tại (MEGA ×1,5 ở bước 10). 1 lúc bình thường.
var effect_multiplier: float = 1.0
var sprays: int = 0

var _puddles: GluePuddles
var _cooldown: float = 0.0
var _puddle_positions: PackedVector3Array = PackedVector3Array()
var _puddle_life: PackedFloat32Array = PackedFloat32Array()
var _next_puddle: int = 0


func _setup_effects(effects: Node) -> void:
	_puddles = effects.get_node_or_null("GluePuddles") as GluePuddles if effects != null else null
	_puddle_positions.resize(MAX_PUDDLES)
	_puddle_life.resize(MAX_PUDDLES)
	_puddle_life.fill(0.0)


func fire(delta: float) -> void:
	for i: int in MAX_PUDDLES:
		if _puddle_life[i] > 0.0:
			_puddle_life[i] = maxf(_puddle_life[i] - delta, 0.0)
	_cooldown -= delta
	if target == null:
		_cooldown = maxf(_cooldown, 0.0)
	else:
		var interval: float = 1.0 / maxf(stats().fire_rate, 0.001)
		while _cooldown <= 0.0:
			_cooldown += interval
			spray(target.global_position)
	_apply_glue(delta)


## Đặt một vũng keo mới tại point (thay vũng cũ nhất).
func spray(point: Vector3) -> void:
	sprays += 1
	_puddle_positions[_next_puddle] = Vector3(point.x, 0.0, point.z)
	_puddle_life[_next_puddle] = stats().slow_duration
	_next_puddle = (_next_puddle + 1) % MAX_PUDDLES


## Bán kính vùng keo (đơn vị Godot), MEGA làm rộng thêm.
func glue_radius() -> float:
	return stats().glue_radius_cells * MapLayout.UNITS_PER_CELL * effect_multiplier


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
	var slow: float = level.slow_amount * effect_multiplier
	var source: int = get_instance_id()
	# Duyệt ngược vì địch bị hạ sẽ rời danh sách.
	for i: int in range(_pool.active.size() - 1, -1, -1):
		var enemy: Enemy = _pool.active[i]
		if not data.target_layers.has(enemy.data.layer) or not in_glue(enemy.global_position):
			continue
		enemy.status.apply_slow(source, slow, level.slow_duration)
		if level.damage_per_second > 0.0:
			_pool.damage(enemy, level.damage_per_second * delta)
