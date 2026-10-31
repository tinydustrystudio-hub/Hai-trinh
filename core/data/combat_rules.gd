class_name CombatRules
extends Resource
## Luật chung của trận (GDD mục 3.1): quy đổi bậc giáp 0–5 sang tỉ lệ giảm sát thương.

@export var armor_tiers: PackedFloat32Array = PackedFloat32Array([0.0, 0.1, 0.2, 0.35, 0.5, 0.65])

@export_group("Xê dịch của địch")
## Mỗi địch lượn nhẹ sang hai bên đường luồng (đơn vị Godot) để đàn trông tự nhiên; tốc độ dọc luồng không đổi.
@export var wander_amplitude: float = 1.2
## Bước sóng của đường lượn (đơn vị Godot dọc luồng): mỗi địch chọn ngẫu nhiên trong khoảng này.
@export var wander_wavelength_min: float = 24.0
@export var wander_wavelength_max: float = 44.0

@export_group("Giãn cách địch")
## Khoảng trống tối thiểu giữa hai thân tàu, tính theo kích thước thân, cho địch yếu nhất (góp ý 4: ít nhất 1/2).
@export var spacing_base_ratio: float = 0.5
## Mỗi lần máu gấp đôi máu tham chiếu thì tỉ lệ khoảng trống tăng thêm chừng này: càng mạnh càng cách xa.
@export var spacing_per_doubling: float = 0.25
## Máu tham chiếu của địch yếu nhất.
@export var spacing_reference_health: float = 60.0


## Bậc giáp gần nhất với một tỉ lệ giáp.
func tier_of(armor: float) -> int:
	var best: int = 0
	for i: int in armor_tiers.size():
		if absf(armor_tiers[i] - armor) < absf(armor_tiers[best] - armor):
			best = i
	return best


## Tỉ lệ giáp của một bậc (kẹp trong bảng).
func armor_of(tier: int) -> float:
	return armor_tiers[clampi(tier, 0, armor_tiers.size() - 1)]


## Tỉ lệ khoảng trống (so với kích thước thân) mà một địch cần quanh mình: 0,5 cho địch yếu nhất, tăng dần theo máu.
func spacing_ratio(max_health: float) -> float:
	var doublings: float = maxf(log(maxf(max_health, 1.0) / maxf(spacing_reference_health, 1.0)) / log(2.0), 0.0)
	return spacing_base_ratio + spacing_per_doubling * doublings


## Khoảng cách tâm-tới-tâm tối thiểu (đơn vị Godot) giữa hai địch trên cùng luồng: nửa hai thân cộng khoảng trống
## theo địch cần nhiều chỗ hơn.
func min_center_gap(a: EnemyData, b: EnemyData, units_per_cell: float) -> float:
	var hull: float = (a.size_cells + b.size_cells) * 0.5
	var gap: float = maxf(spacing_ratio(a.max_health) * a.size_cells, spacing_ratio(b.max_health) * b.size_cells)
	return (hull + gap) * units_per_cell
