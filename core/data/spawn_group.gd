class_name SpawnGroup
extends Resource
## Một nhóm địch trong một đợt: cùng loại, cùng luồng, sinh cách nhau đều.

@export var enemy: EnemyData
@export var count: int = 1
## Khoảng cách giữa hai con liền nhau, giây.
@export var interval: float = 1.5
## Chỉ số luồng trong MapLayout.lane_points.
@export var lane_index: int = 0
## Độ trễ tính từ đầu đợt tới con đầu tiên, giây.
@export var delay: float = 0.0


## Thời điểm (giây, tính từ đầu đợt) con cuối cùng xuất hiện.
func last_spawn_time() -> float:
	return delay + interval * float(maxi(count - 1, 0))
