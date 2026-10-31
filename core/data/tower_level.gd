class_name TowerLevel
extends Resource
## Số liệu một cấp lô cốt (GDD Phần 3). Trường nào không dùng cho loại lô cốt đó thì để 0.

## Giá Thép để lên cấp này (cấp 1: giá xây).
@export var steel_cost: int = 0
## Sát thương mỗi phát.
@export var damage: float = 0.0
## Tốc bắn, phát/giây.
@export var fire_rate: float = 0.0
## Tầm, ô.
@export var range_cells: float = 0.0
@export_group("Lô Cốt Keo")
## Mức làm chậm (0–1).
@export var slow_amount: float = 0.0
## Thời gian làm chậm sau mỗi lần phun, giây.
@export var slow_duration: float = 0.0
## Bán kính vùng keo, ô.
@export var glue_radius_cells: float = 0.0
## Sát thương mỗi giây trong vùng keo.
@export var damage_per_second: float = 0.0

@export_group("Lô Cốt Tia Sáng")
## Sát thương mỗi giây tăng thêm tối đa (0,8 = +80%) sau khi giữ tia trên cùng một mục tiêu beam_ramp_seconds giây.
@export var beam_ramp_bonus: float = 0.0
@export var beam_ramp_seconds: float = 3.0
## Tỉ lệ giáp tia sáng bỏ qua (ánh sáng hội tụ làm nóng lớp giáp).
@export var beam_armor_ignore: float = 0.0


func range_units() -> float:
	return range_cells * MapLayout.UNITS_PER_CELL
