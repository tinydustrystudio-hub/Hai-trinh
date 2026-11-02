class_name EconomyData
extends Resource
## Luật Thép trong trận (GDD mục 3.1, Hồi I mức Trung bình). Thép khởi đầu nằm trong MapLayout.

## Thép cộng thêm đầu mỗi đợt.
@export var wave_bonus: int = 20
## Tỉ lệ hoàn lại khi bán lô cốt, trên tổng Thép đã bỏ vào nó.
@export_range(0.0, 1.0) var sell_refund: float = 0.7

## Thưởng Tiền Vàng vào ví khi thắng một trận (số tạm). Tiền kiếm được trong trận (diệt địch, thưởng đợt) luôn cộng vào ví.
@export var victory_bonus: int = 100

@export_group("Đảo vệ tinh")
## Đảo là vật phẩm: mua một lần là có mãi. Dùng đảo do người chơi tự đặt vào màn thì tốn phí: đảo tự đặt thứ nhất
## island_use_base, mỗi đảo tiếp theo cộng thêm island_use_step (200, 250, 300…). Đảo cấp sẵn của màn không tốn phí.
@export var island_use_base: int = 200
@export var island_use_step: int = 50
## Giá mua đảo (vật phẩm, mua một lần): đảo mua thêm thứ nhất (đảo thứ 5 của màn 1) island_buy_base, mỗi đảo tiếp theo
## cộng thêm island_buy_step (250, 300, 350, 400…).
@export var island_buy_base: int = 250
@export var island_buy_step: int = 50
## Phí dời một đảo đã đặt = giá xây lô cốt rẻ nhất nhân hệ số này (làm tròn xuống, tối thiểu 1).
@export_range(0.0, 4.0) var island_move_ratio: float = 1.0
## Phí kéo một đảo đang mang lô cốt (lô cốt đi theo đảo) = giá lô cốt rẻ nhất nhân hệ số này, một khoản gộp (60 → 180).
@export_range(0.0, 8.0) var island_loaded_move_ratio: float = 3.0
## Phí dời một lô cốt sang bệ khác = giá xây lô cốt rẻ nhất nhân hệ số này (làm tròn xuống, tối thiểu 1). Lô cốt giữ nguyên cấp,
## nhánh và thanh Quá tải khi dời.
@export_range(0.0, 2.0) var tower_move_ratio: float = 1.0
## Kéo đảo như kéo xà lan: tốc độ tối đa (đơn vị Godot mỗi giây) và gia tốc khởi hành/phanh (đơn vị mỗi giây bình phương).
@export var island_tow_speed: float = 7.0
@export var island_tow_accel: float = 3.0


## Giá mua đảo mua thêm thứ n (đếm từ 1; đảo cấp sẵn không tính).
func island_buy_cost(n: int) -> int:
	return island_buy_base + island_buy_step * maxi(n - 1, 0)


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


## Phí kéo đảo đang mang lô cốt, theo giá xây lô cốt rẻ nhất (cấp 1).
func island_loaded_move_cost(cheapest_tower_cost: int) -> int:
	return maxi(floori(float(cheapest_tower_cost) * island_loaded_move_ratio), 1)


## Phí dời lô cốt, theo giá xây lô cốt rẻ nhất (cấp 1).
func tower_move_cost(cheapest_tower_cost: int) -> int:
	return maxi(floori(float(cheapest_tower_cost) * tower_move_ratio), 1)


@export_group("Nâng cấp công trình (số tạm)")
## Giá lên cấp 2 của công trình có hệ số 1,0; mỗi cấp sau nhân thêm building_growth (200, 320, 512, 819 → làm tròn
## tới 10). Công trình khác nhau nhân thêm hệ số riêng ở BuildingData.upgrade_multiplier. Số tạm, chỉnh sau khi chơi thử.
@export var building_base_cost: int = 200
@export var building_growth: float = 1.6


## Giá lên cấp level (2–5) của một công trình có hệ số multiplier, làm tròn tới 10 Tiền Vàng; cấp 1 và dưới là 0.
func building_upgrade_cost(level: int, multiplier: float = 1.0) -> int:
	if level < 2:
		return 0
	var raw: float = float(building_base_cost) * pow(building_growth, float(level - 2)) * multiplier
	return int(roundf(raw / 10.0)) * 10


## Tổng giá đưa công trình từ cấp 1 lên cấp level.
func building_total_cost(level: int, multiplier: float = 1.0) -> int:
	var total: int = 0
	for l: int in range(2, level + 1):
		total += building_upgrade_cost(l, multiplier)
	return total
