class_name WaveData
extends Resource
## Danh sách đợt của một màn.

@export var id: StringName = &""
## Thời gian chuẩn bị trước đợt đầu, giây.
@export var first_wave_delay: float = 10.0
@export var waves: Array[Wave] = []


func wave_count() -> int:
	return waves.size()


func total_enemy_count() -> int:
	var total: int = 0
	for wave: Wave in waves:
		total += wave.enemy_count()
	return total
