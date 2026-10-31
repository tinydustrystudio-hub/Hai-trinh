class_name WeatherData
extends Resource
## Một kiểu thời tiết của trận (góp ý 4, mục 12): bình thường, mưa, bão. Chỉ đổi hình ảnh và âm thanh
## (sóng, gió, mưa, sấm sét, ánh sáng), không đổi số liệu chiến đấu.

@export var id: StringName = &""
@export var name_key: StringName = &""
@export_group("Biển")
## Nhân độ cao mọi lớp sóng (1 = bình thường).
@export var wave_boost: float = 1.0
## Gió đổi chiều: các lớp sóng quay quanh một góc dao động tối đa chừng này (radian), chu kỳ wind_period giây.
@export var wind_swing: float = 0.0
@export var wind_period: float = 24.0
## Nhân độ gợn mặt nước (normal map).
@export var chop: float = 1.0
@export_group("Trời")
## Mưa rơi, 0–1.
@export_range(0.0, 1.0) var rain: float = 0.0
## Trời tối đi bao nhiêu, 0–1: nắng yếu đi, nước tối và ít lấp lánh.
@export_range(0.0, 1.0) var darkness: float = 0.0
## Sấm sét: khoảng cách giữa hai tia chớp (giây), 0 = không có.
@export var lightning_min_seconds: float = 0.0
@export var lightning_max_seconds: float = 0.0


func has_lightning() -> bool:
	return lightning_min_seconds > 0.0 and lightning_max_seconds >= lightning_min_seconds
