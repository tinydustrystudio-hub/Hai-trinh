class_name BuildingData
extends Resource
## Công trình hỗ trợ trên đảo chính, nâng cấp ở màn Căn cứ bằng Tiền Vàng (concept pack mục C, GDD 5.3).
## Hiệu ứng chơi (giảm sóng, thêm vàng khởi đầu…) là số cân bằng, để sau khi chơi thử; hiện chỉ đổi hình khối.

const MAX_LEVEL: int = 5

@export var id: StringName = &""
@export var name_key: StringName = &""
@export var description_key: StringName = &""
## Hệ số nhân giá nâng cấp (EconomyData.building_upgrade_cost).
@export var upgrade_multiplier: float = 1.0
