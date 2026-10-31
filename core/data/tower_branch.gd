class_name TowerBranch
extends TowerLevel
## Một nhánh cấp 5 (GDD Phần 3): số liệu như một cấp, cộng tên, mô tả và tham số kỹ năng riêng.
## Trường nào không dùng cho nhánh đó thì để mặc định.

@export var id: StringName = &""
@export var name_key: StringName = &""
## Một câu mô tả nhánh.
@export var description_key: StringName = &""
@export var skill_name_key: StringName = &""
@export var skill_description_key: StringName = &""

@export_group("Súng Máy")
## Số mục tiêu bắn cùng lúc (Mưa Đạn: 3).
@export var targets_per_shot: int = 1
## Tỉ lệ giáp bị bỏ qua (Xuyên Giáp: 0,7).
@export_range(0.0, 1.0) var armor_ignore: float = 0.0
## Quét Ngang: cứ chừng này giây quét một hình quạt (0 = không có).
@export var sweep_interval: float = 0.0
## Góc mở của hình quạt, độ.
@export var sweep_angle_degrees: float = 90.0
## Sát thương mỗi lần quét, tính theo sát thương một phát.
@export var sweep_damage_multiplier: float = 1.0
## Đạn Lõi Thép: cứ phát thứ chừng này (0 = không có).
@export var core_round_every: int = 0
@export var core_round_multiplier: float = 1.0
## Chỉ tác dụng lên địch có giáp từ bậc này trở lên (GDD mục 3.1).
@export var core_round_min_armor_tier: int = 3

@export_group("Lô Cốt Keo")
## Hồ Keo: vùng keo nằm cố định trên luồng gần nhất.
@export var fixed_lake: bool = false
## Dính Chặt: cứ chừng này giây giữ đứng yên mọi địch trong hồ (0 = không có).
@export var hold_interval: float = 0.0
@export var hold_duration: float = 0.0
## Trùm và tàu tinh nhuệ không bị giữ, chỉ chậm thêm chừng này.
@export var hold_resistant_slow: float = 0.0
## Keo Ăn Mòn: mỗi lần phun trúng giảm chừng này bậc giáp trong armor_reduction_duration giây.
@export var armor_tier_reduction: int = 0
@export var armor_reduction_duration: float = 0.0
## Bóc Giáp: trúng chừng này lần phun liên tiếp thì mất toàn bộ giáp trong armor_break_duration giây (0 = không có).
@export var armor_break_hits: int = 0
@export var armor_break_duration: float = 0.0
