class_name LightingData
extends Resource
## Ánh sáng của một màn theo cốt truyện: bình minh, ban ngày, hoàng hôn (P6). Gồm nắng, ánh sáng nền, chỉnh màu,
## glow, tối viền màn hình và bảng màu biển, trời. Chỉ đổi hình ảnh. Cố định suốt một màn (không đổi giữa chừng).

@export var id: StringName = &""
@export var name_key: StringName = &""
@export_group("Nắng")
@export var sun_color: Color = Color(1.0, 0.88, 0.7)
@export var sun_energy: float = 1.35
## Hướng từ mặt nước tới mặt trời; càng thấp (y nhỏ) thì bóng giả càng dài.
@export var sun_direction: Vector3 = Vector3(0.45, 0.6, -0.65)
@export_group("Màn hình")
@export var ambient_color: Color = Color(0.55, 0.68, 0.92)
@export var ambient_energy: float = 0.75
@export var background_color: Color = Color(0.02, 0.07, 0.2)
@export var contrast: float = 1.06
@export var saturation: float = 1.08
@export var brightness: float = 1.0
@export var glow_intensity: float = 0.5
## Ngưỡng sáng bắt đầu lóe (glow_hdr_threshold).
@export var glow_threshold: float = 1.1
## Độ tối viền màn hình, 0–1, và màu của viền.
@export_range(0.0, 1.0) var vignette: float = 0.16
@export var vignette_color: Color = Color(0.0, 0.03, 0.08)
@export_group("Biển và trời")
@export var sea_deep: Color = Color(0.02, 0.07, 0.2)
@export var sea_crest: Color = Color(0.05, 0.2, 0.38)
@export var sea_shallow: Color = Color(0.06, 0.32, 0.45)
@export var sky_horizon: Color = Color(0.72, 0.84, 0.95)
@export var sky_zenith: Color = Color(0.3, 0.52, 0.85)
@export var cloud_color: Color = Color(0.86, 0.91, 0.97)
