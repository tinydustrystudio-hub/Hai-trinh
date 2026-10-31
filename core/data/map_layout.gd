class_name MapLayout
extends Resource
## Bố cục một bản đồ trận: khối đảo, vị trí bệ, điểm của từng luồng và giới hạn camera.
## Mọi vị trí tính bằng đơn vị Godot trên mặt nước (y = 0); 1 ô = UNITS_PER_CELL đơn vị.

## 1 ô (đơn vị tầm trong GDD) = khoảng cách giữa hai bệ liền nhau.
const UNITS_PER_CELL: float = 4.0

@export var id: StringName = &""
## Khóa tên bản đồ trong bảng dịch.
@export var name_key: StringName = &""

@export_group("Trận")
## Thép khởi đầu (GDD mục 3.1, Hồi I mức Trung bình).
@export var starting_steel: int = 200
## Độ Nổi khởi đầu (kế hoạch tháng 1, mục 5.1).
@export var starting_buoyancy: int = 20

@export_group("Đảo")
## Tâm pháo đài lục giác (đảo chính), trên mặt nước.
@export var fortress_center: Vector3 = Vector3.ZERO
## Bán kính ngoài của pháo đài (từ tâm tới đỉnh lục giác của đê chắn sóng), đơn vị Godot.
@export var fortress_radius: float = 14.0
## Tâm các đảo vệ tinh; mỗi đảo mang một bệ ở giữa. Bệ không nằm trên đảo vệ tinh thì nằm trên mỏm bến.
@export var satellite_centers: PackedVector3Array = PackedVector3Array()
## Bán kính đảo vệ tinh (GDD mục 8.6: đường kính khoảng 1,5 ô).
@export var satellite_radius: float = 3.0
## Hướng từ mặt nước tới mặt trời (nắng chiếu từ một hướng).
@export var sun_direction: Vector3 = Vector3(0.45, 0.6, -0.65)

@export_group("Bệ và luồng")
## Tâm của từng bệ lô cốt.
@export var pad_positions: PackedVector3Array = PackedVector3Array()
## Khóa tên của từng luồng trong bảng dịch, cùng thứ tự với lane_points.
@export var lane_name_keys: Array[StringName] = []
## Điểm của từng luồng, từ chỗ địch xuất hiện tới chỗ địch lọt vào đảo.
@export var lane_points: Array[PackedVector3Array] = []

@export_group("Camera")
## Vùng điểm nhìn của camera (trên mặt nước, theo x và z) được trượt tới khi thu nhỏ hết cỡ.
@export var camera_bounds: Rect2 = Rect2(-40.0, -40.0, 80.0, 60.0)
## Vùng điểm nhìn được trượt tới khi phóng to hết cỡ (giới hạn bản đồ); ở giữa thì nội suy.
@export var camera_zoom_bounds: Rect2 = Rect2(-60.0, -50.0, 120.0, 100.0)
## Điểm nhìn lúc vào trận.
@export var camera_start: Vector2 = Vector2.ZERO
## Khoảng cách từ camera tới điểm nhìn khi thu nhỏ hết cỡ (thấy toàn bộ chiến trường).
@export var camera_distance: float = 60.0
## Khoảng cách khi phóng to hết cỡ (đảo chính gần đầy màn hình).
@export var camera_min_distance: float = 30.0
## Góc nghiêng của camera so với mặt nước, độ.
@export var camera_pitch_degrees: float = 55.0


func lane_count() -> int:
	return lane_points.size()


func pad_count() -> int:
	return pad_positions.size()


## Bệ nằm trên đảo vệ tinh (trùng tâm một đảo vệ tinh) hay trên mỏm bến của đảo chính.
func is_satellite_pad(index: int) -> bool:
	var pad: Vector3 = pad_positions[index]
	for center: Vector3 in satellite_centers:
		if Vector2(center.x - pad.x, center.z - pad.z).length() < satellite_radius * 0.5:
			return true
	return false
