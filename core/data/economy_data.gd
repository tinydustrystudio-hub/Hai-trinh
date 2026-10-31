class_name EconomyData
extends Resource
## Luật Thép trong trận (GDD mục 3.1, Hồi I mức Trung bình). Thép khởi đầu nằm trong MapLayout.

## Thép cộng thêm đầu mỗi đợt.
@export var wave_bonus: int = 20
## Tỉ lệ hoàn lại khi bán lô cốt, trên tổng Thép đã bỏ vào nó.
@export_range(0.0, 1.0) var sell_refund: float = 0.7
