class_name CombatRules
extends Resource
## Luật chung của trận (GDD mục 3.1): quy đổi bậc giáp 0–5 sang tỉ lệ giảm sát thương.

@export var armor_tiers: PackedFloat32Array = PackedFloat32Array([0.0, 0.1, 0.2, 0.35, 0.5, 0.65])


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
