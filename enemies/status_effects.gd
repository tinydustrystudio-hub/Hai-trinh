class_name StatusEffects
extends RefCounted
## Hiệu ứng trên một địch.
## - Làm chậm (kế hoạch mục 5.4): mỗi nguồn (lô cốt) giữ một mức chậm và thời hạn; nhiều nguồn cộng dồn,
##   trần 70% (trùm 40%); cùng một nguồn chỉ làm mới, không cộng thêm.
## - Giữ đứng yên (Dính Chặt): tốc độ về 0 trong thời hạn.
## - Giảm bậc giáp (Keo Ăn Mòn) và mất toàn bộ giáp (Bóc Giáp), mỗi thứ một thời hạn.
## - Đếm số lần phun liên tiếp trúng từ một nguồn (cho Bóc Giáp).
## Mảng cố định, không cấp phát trong vòng lặp trận.

## Số nguồn làm chậm cùng lúc tối đa trên một địch.
const MAX_SOURCES: int = 8
## Trần làm chậm (GDD mục 3.4).
const SLOW_CAP: float = 0.7
const BOSS_SLOW_CAP: float = 0.4

var _sources: PackedInt64Array = PackedInt64Array()
var _amounts: PackedFloat32Array = PackedFloat32Array()
var _time_left: PackedFloat32Array = PackedFloat32Array()
var _hold_left: float = 0.0
var _armor_reduction: int = 0
var _armor_reduction_left: float = 0.0
var _armor_break_left: float = 0.0
var _spray_source: int = 0
var _spray_last: int = -1
var _spray_streak: int = 0


func _init() -> void:
	_sources.resize(MAX_SOURCES)
	_amounts.resize(MAX_SOURCES)
	_time_left.resize(MAX_SOURCES)
	clear()


func clear() -> void:
	_sources.fill(0)
	_amounts.fill(0.0)
	_time_left.fill(0.0)
	_hold_left = 0.0
	_armor_reduction = 0
	_armor_reduction_left = 0.0
	_armor_break_left = 0.0
	_spray_source = 0
	_spray_last = -1
	_spray_streak = 0


## Làm chậm amount (0–1) trong duration giây từ nguồn source (khác 0).
func apply_slow(source: int, amount: float, duration: float) -> void:
	var free: int = -1
	for i: int in MAX_SOURCES:
		if _time_left[i] > 0.0 and _sources[i] == source:
			_amounts[i] = amount
			_time_left[i] = maxf(_time_left[i], duration)
			return
		if free == -1 and _time_left[i] <= 0.0:
			free = i
	if free == -1:
		# Hết chỗ: thay nguồn sắp hết hạn nhất.
		free = 0
		for i: int in MAX_SOURCES:
			if _time_left[i] < _time_left[free]:
				free = i
	_sources[free] = source
	_amounts[free] = amount
	_time_left[free] = duration


func advance(delta: float) -> void:
	for i: int in MAX_SOURCES:
		if _time_left[i] > 0.0:
			_time_left[i] = maxf(_time_left[i] - delta, 0.0)
	_hold_left = maxf(_hold_left - delta, 0.0)
	_armor_reduction_left = maxf(_armor_reduction_left - delta, 0.0)
	_armor_break_left = maxf(_armor_break_left - delta, 0.0)


## Giữ đứng yên duration giây.
func hold(duration: float) -> void:
	_hold_left = maxf(_hold_left, duration)


func is_held() -> bool:
	return _hold_left > 0.0


## Giảm tiers bậc giáp trong duration giây (lần sau thay lần trước nếu mạnh hơn hoặc bằng).
func reduce_armor(tiers: int, duration: float) -> void:
	if tiers >= _armor_reduction or _armor_reduction_left <= 0.0:
		_armor_reduction = tiers
	_armor_reduction_left = maxf(_armor_reduction_left, duration)


## Mất toàn bộ giáp trong duration giây.
func break_armor(duration: float) -> void:
	_armor_break_left = maxf(_armor_break_left, duration)


func is_armor_broken() -> bool:
	return _armor_break_left > 0.0


## Giáp đang có, sau giảm bậc và bóc giáp.
func effective_armor(base_armor: float, rules: CombatRules) -> float:
	if _armor_break_left > 0.0:
		return 0.0
	if _armor_reduction_left > 0.0 and _armor_reduction > 0:
		return rules.armor_of(rules.tier_of(base_armor) - _armor_reduction)
	return base_armor


## Ghi một lần phun thứ spray_index của nguồn source trúng địch; trả số lần trúng liên tiếp.
## Lần phun liền trước của cùng nguồn không trúng thì đếm lại từ 1.
func record_spray_hit(source: int, spray_index: int) -> int:
	if source == _spray_source and spray_index == _spray_last + 1:
		_spray_streak += 1
	elif not (source == _spray_source and spray_index == _spray_last):
		_spray_streak = 1
	_spray_source = source
	_spray_last = spray_index
	return _spray_streak


func reset_spray_streak() -> void:
	_spray_streak = 0


## Tổng mức chậm đang có, đã kẹp theo trần.
func total_slow(is_boss: bool) -> float:
	var total: float = 0.0
	for i: int in MAX_SOURCES:
		if _time_left[i] > 0.0:
			total += _amounts[i]
	return minf(total, BOSS_SLOW_CAP if is_boss else SLOW_CAP)


func is_slowed() -> bool:
	for i: int in MAX_SOURCES:
		if _time_left[i] > 0.0 and _amounts[i] > 0.0:
			return true
	return false


## Hệ số tốc độ của một địch lúc này: đang bị giữ thì đứng yên.
func speed_factor_now(is_boss: bool) -> float:
	if _hold_left > 0.0:
		return 0.0
	return speed_factor(total_slow(is_boss))


## Hệ số tốc độ: tốc độ = tốc độ gốc × (1 − tổng mức chậm).
static func speed_factor(total_slow: float) -> float:
	return 1.0 - clampf(total_slow, 0.0, 1.0)
