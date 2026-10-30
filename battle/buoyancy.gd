class_name Buoyancy
extends Node
## Độ Nổi: máu căn cứ. Địch lọt thì trừ; về 0 thì báo chìm. Đảo nghiêng nhẹ theo mức đã mất.

signal changed(value: int, max_value: int)
signal depleted

## Góc nghiêng lớn nhất của đảo khi Độ Nổi về 0, độ.
const MAX_TILT_DEGREES: float = 6.0

var value: int = 20
var max_value: int = 20


func reset(starting: int) -> void:
	max_value = maxi(starting, 1)
	value = max_value
	changed.emit(value, max_value)


## Trừ Độ Nổi; trả true nếu lần này làm Độ Nổi về 0.
func take_leak(damage: int) -> bool:
	if value <= 0:
		return false
	value = maxi(value - maxi(damage, 0), 0)
	changed.emit(value, max_value)
	if value == 0:
		depleted.emit()
		return true
	return false


func is_sunk() -> bool:
	return value <= 0


## Góc nghiêng của đảo (độ) theo phần Độ Nổi đã mất.
func tilt_degrees() -> float:
	return MAX_TILT_DEGREES * (1.0 - float(value) / float(max_value))
