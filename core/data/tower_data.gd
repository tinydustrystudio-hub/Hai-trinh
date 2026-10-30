class_name TowerData
extends Resource
## Số liệu một loại lô cốt và MEGA cơ bản của nó (GDD mục 3.1–3.4; kế hoạch tháng 1, mục 5.1).

@export var id: StringName = &""
## Khóa tên trong bảng dịch.
@export var name_key: StringName = &""
## Các tầng đánh được.
@export var target_layers: Array[EnemyData.Layer] = [EnemyData.Layer.SURFACE]
## Cấp 1 tới cấp 5, theo thứ tự.
@export var levels: Array[TowerLevel] = []
@export_group("Quá tải và MEGA")
## Thời gian bắn liên tục để nạp đầy thanh Quá tải, giây.
@export var overload_charge_seconds: float = 14.0
@export var mega_duration: float = 5.0
## Hệ số sát thương (hoặc hiệu ứng) khi đang MEGA.
@export var mega_multiplier: float = 3.0
@export var cooldown_duration: float = 7.0
## Sức bắn khi đang làm mát (0–1).
@export var cooldown_fire_power: float = 0.2
@export var color: Color = Color(0.16, 0.42, 0.66)


func max_level() -> int:
	return levels.size()


func level(number: int) -> TowerLevel:
	return levels[clampi(number, 1, levels.size()) - 1]


## Tổng Thép đã bỏ vào lô cốt khi nó ở cấp number (xây + mọi lần nâng).
func total_cost(number: int) -> int:
	var total: int = 0
	for i: int in clampi(number, 0, levels.size()):
		total += levels[i].steel_cost
	return total


func can_target(layer: EnemyData.Layer) -> bool:
	return target_layers.has(layer)
