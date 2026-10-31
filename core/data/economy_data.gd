class_name EconomyData
extends Resource
## Luật Thép trong trận (GDD mục 3.1, Hồi I mức Trung bình). Thép khởi đầu nằm trong MapLayout.

## Thép cộng thêm đầu mỗi đợt.
@export var wave_bonus: int = 20
## Tỉ lệ hoàn lại khi bán lô cốt, trên tổng Thép đã bỏ vào nó.
@export_range(0.0, 1.0) var sell_refund: float = 0.7

@export_group("Đảo vệ tinh")
## Đảo là vật phẩm: mua một lần là có mãi. Dùng đảo do người chơi tự đặt vào màn thì tốn phí: đảo tự đặt thứ nhất
## island_use_base, mỗi đảo tiếp theo cộng thêm island_use_step (200, 250, 300…). Đảo cấp sẵn của màn không tốn phí.
@export var island_use_base: int = 200
@export var island_use_step: int = 50
## Phí dời một đảo đã đặt = giá xây lô cốt rẻ nhất nhân hệ số này (làm tròn xuống, tối thiểu 1).
@export_range(0.0, 1.0) var island_move_ratio: float = 0.5


## Phí dùng đảo tự đặt thứ n (đếm từ 1) trong một màn.
func island_use_cost(n: int) -> int:
	return island_use_base + island_use_step * maxi(n - 1, 0)


## Tổng phí dùng n đảo tự đặt.
func island_use_total(n: int) -> int:
	var total: int = 0
	for i: int in maxi(n, 0):
		total += island_use_cost(i + 1)
	return total


## Phí dời đảo, theo giá xây lô cốt rẻ nhất (cấp 1) trong danh sách.
func island_move_cost(cheapest_tower_cost: int) -> int:
	return maxi(floori(float(cheapest_tower_cost) * island_move_ratio), 1)
