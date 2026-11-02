class_name BuildingData
extends Resource
## Công trình hỗ trợ trên đảo chính, nâng cấp ở màn Căn cứ bằng Tiền Vàng (concept pack mục C, GDD 5.3).
## Mỗi công trình có một hiệu ứng chơi tăng theo cấp (effect_at): số cân bằng ghi trong data/buildings/*.tres.
## Hiệu ứng có `implemented = true` đã nối vào trận; còn lại mới là dữ liệu và chữ hiển thị, chờ tính năng tương ứng (máu lô cốt,
## địch tàng hình, tàu chiến, máy bay).

const MAX_LEVEL: int = 5

@export var id: StringName = &""
@export var name_key: StringName = &""
@export var description_key: StringName = &""
## Hệ số nhân giá nâng cấp (EconomyData.building_upgrade_cost).
@export var upgrade_multiplier: float = 1.0

## Loại hiệu ứng: max_buoyancy_pct (Độ Nổi tối đa), tower_hp_pct (máu lô cốt), mega_seconds_pct (thời gian MEGA),
## radar_range_pct (tầm ra-đa, thấy địch tàng hình), warship_slots (số tàu chiến), aircraft_slots (số máy bay).
@export var effect_kind: StringName = &""
## Giá trị ở cấp 1 và mức tăng thêm mỗi cấp (đơn vị theo effect_kind: phần trăm hoặc số lượng).
@export var effect_base: float = 0.0
@export var effect_per_level: float = 0.0
## Khoá chữ mô tả hiệu ứng, có một chỗ %s cho giá trị (ví dụ "Độ Nổi tối đa +%s%%").
@export var effect_key: StringName = &""
## Hiệu ứng đã nối vào trận chưa.
@export var implemented: bool = false


## Giá trị hiệu ứng ở cấp level (1–5).
func effect_at(level: int) -> float:
	return effect_base + effect_per_level * float(clampi(level, 1, MAX_LEVEL) - 1)
