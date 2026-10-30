class_name EnemyData
extends Resource
## Số liệu một loại địch (GDD Phần 4, quy đổi sang số ở mục 3.1; tốc độ và Độ Nổi theo kế hoạch tháng 1, mục 5.1).

## Tầng chiến đấu (GDD mục 4.1).
enum Layer { SURFACE, UNDERWATER, AIR }
## Hình khối thô, để nhận ra từng loại bằng hình bóng chứ không chỉ bằng màu (GDD mục 1.8).
enum Hull { SKIFF, RAM, CRAB }

@export var id: StringName = &""
## Khóa tên trong bảng dịch.
@export var name_key: StringName = &""
@export var max_health: float = 60.0
## Tốc độ, ô/giây.
@export var speed_cells: float = 0.8
## Tỉ lệ giảm sát thương mỗi phát (0–1).
@export_range(0.0, 1.0) var armor: float = 0.1
@export var layer: Layer = Layer.SURFACE
## Trùm: làm chậm tối đa 40% thay vì 70%.
@export var is_boss: bool = false
## Độ Nổi mất khi lọt vào đảo.
@export var buoyancy_damage: int = 1
## Thép nhận được khi hạ.
@export var steel_reward: int = 5
## Kích thước, ô (1 ô = một bệ).
@export var size_cells: float = 0.8
@export var hull: Hull = Hull.SKIFF
@export var body_color: Color = Color(0.2, 0.2, 0.22)
@export var accent_color: Color = Color(1.0, 0.8, 0.1)


## Tốc độ theo đơn vị Godot mỗi giây.
func speed_units() -> float:
	return speed_cells * MapLayout.UNITS_PER_CELL
