class_name Targeting
extends RefCounted
## Chọn mục tiêu cho lô cốt (kế hoạch mục 5.2): địch đúng tầng, trong tầm, đi xa nhất trên luồng
## (còn ít đường nhất tới đảo). Lô cốt gọi lại RETARGET_INTERVAL giây một lần, không phải mỗi khung.

## 5 lần mỗi giây.
const RETARGET_INTERVAL: float = 0.2


## Địch tốt nhất trong danh sách, hoặc null. origin là vị trí lô cốt; tầm tính trên mặt nước.
static func pick(enemies: Array[Enemy], origin: Vector3, range_units: float, layers: Array[EnemyData.Layer]) -> Enemy:
	var best: Enemy = null
	var best_left: float = INF
	var range_squared: float = range_units * range_units
	for enemy: Enemy in enemies:
		if not can_hit(enemy, origin, range_squared, layers):
			continue
		var left: float = enemy.lane.length() - enemy.distance
		if left < best_left:
			best = enemy
			best_left = left
	return best


## Còn bắn được địch này không: còn sống, đúng tầng, trong tầm (range_squared là bình phương tầm).
static func can_hit(enemy: Enemy, origin: Vector3, range_squared: float, layers: Array[EnemyData.Layer]) -> bool:
	if enemy == null or not enemy.active or enemy.is_dead():
		return false
	if not layers.has(enemy.data.layer):
		return false
	var dx: float = enemy.position.x - origin.x
	var dz: float = enemy.position.z - origin.z
	return dx * dx + dz * dz <= range_squared
