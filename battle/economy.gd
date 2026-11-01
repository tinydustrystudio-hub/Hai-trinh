class_name Economy
extends Node
## Thép trong trận: khởi đầu theo MapLayout, cộng thưởng khi hạ địch, cộng thưởng đầu mỗi đợt,
## trừ khi xây và nâng, hoàn một phần khi bán (kế hoạch mục 5.4; số trong data/economy.tres).

signal changed(value: int)

@export var data: EconomyData = preload("res://data/economy.tres")

var steel: int = 0
## Tiền kiếm được trong trận (diệt địch, thưởng đợt); không tính Tiền Vàng khởi đầu hay tiền hoàn khi bán.
var earned: int = 0


func reset(starting: int) -> void:
	steel = maxi(starting, 0)
	earned = 0
	changed.emit(steel)


func can_afford(cost: int) -> bool:
	return cost <= steel


## Trừ Thép nếu đủ; trả true nếu đã trừ.
func spend(cost: int) -> bool:
	if cost < 0 or not can_afford(cost):
		return false
	steel -= cost
	changed.emit(steel)
	return true


func earn(amount: int) -> void:
	if amount <= 0:
		return
	steel += amount
	earned += amount
	changed.emit(steel)


## Tiền hoàn khi bán lô cốt: vào Tiền Vàng trong trận nhưng không tính là tiền kiếm được.
func receive_refund(amount: int) -> void:
	if amount <= 0:
		return
	steel += amount
	changed.emit(steel)


## Thưởng đầu đợt.
func on_wave_started() -> void:
	earn(data.wave_bonus)


## Thép hoàn lại khi bán một lô cốt đã bỏ vào tổng invested Thép (làm tròn xuống).
func refund_for(invested: int) -> int:
	# Cộng một chút trước khi làm tròn để 70 × 0,7 ra đúng 49 (sai số dấu phẩy động).
	return floori(float(invested) * data.sell_refund + 0.0001)
