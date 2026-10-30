class_name Wave
extends Resource
## Một đợt địch: các nhóm sinh song song, rồi nghỉ trước đợt kế tiếp.

@export var groups: Array[SpawnGroup] = []
## Thời gian nghỉ sau khi đợt này bị dọn sạch, giây.
@export var rest_after: float = 8.0


func enemy_count() -> int:
	var total: int = 0
	for group: SpawnGroup in groups:
		total += group.count
	return total


## Thời điểm (giây, tính từ đầu đợt) con cuối cùng của đợt xuất hiện.
func duration() -> float:
	var longest: float = 0.0
	for group: SpawnGroup in groups:
		longest = maxf(longest, group.last_spawn_time())
	return longest


## Các luồng có địch trong đợt, không trùng, theo thứ tự tăng dần.
func lane_indices() -> PackedInt32Array:
	var result: PackedInt32Array = PackedInt32Array()
	for group: SpawnGroup in groups:
		if not result.has(group.lane_index):
			result.append(group.lane_index)
	result.sort()
	return result
