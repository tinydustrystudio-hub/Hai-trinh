class_name StatusEffects
extends RefCounted
## Hiệu ứng làm chậm trên một địch (kế hoạch mục 5.4): mỗi nguồn (lô cốt) giữ một mức chậm và thời hạn;
## nhiều nguồn cộng dồn, trần 70% (trùm 40%); cùng một nguồn chỉ làm mới, không cộng thêm.
## Mảng cố định, không cấp phát trong vòng lặp trận.

## Số nguồn làm chậm cùng lúc tối đa trên một địch.
const MAX_SOURCES: int = 8
## Trần làm chậm (GDD mục 3.4).
const SLOW_CAP: float = 0.7
const BOSS_SLOW_CAP: float = 0.4

var _sources: PackedInt64Array = PackedInt64Array()
var _amounts: PackedFloat32Array = PackedFloat32Array()
var _time_left: PackedFloat32Array = PackedFloat32Array()


func _init() -> void:
	_sources.resize(MAX_SOURCES)
	_amounts.resize(MAX_SOURCES)
	_time_left.resize(MAX_SOURCES)
	clear()


func clear() -> void:
	_sources.fill(0)
	_amounts.fill(0.0)
	_time_left.fill(0.0)


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


## Hệ số tốc độ: tốc độ = tốc độ gốc × (1 − tổng mức chậm).
static func speed_factor(total_slow: float) -> float:
	return 1.0 - clampf(total_slow, 0.0, 1.0)
