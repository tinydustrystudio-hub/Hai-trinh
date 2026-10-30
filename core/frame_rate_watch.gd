class_name FrameRateWatch
extends RefCounted
## Theo dõi khung hình: báo một lần khi khung/giây dưới ngưỡng liên tục đủ lâu
## (kế hoạch mục 7: dưới 30 khung/giây liên tục 5 giây thì hạ chất lượng nước).

var threshold_fps: float = 30.0
var hold_seconds: float = 5.0
var triggered: bool = false

var _below_for: float = 0.0


func _init(threshold: float = 30.0, hold: float = 5.0) -> void:
	threshold_fps = threshold
	hold_seconds = hold


## Đưa vào khung/giây hiện tại và thời gian thật đã trôi; trả true đúng một lần khi vừa chạm điều kiện.
func update(fps: float, real_delta: float) -> bool:
	if triggered:
		return false
	if fps < threshold_fps:
		_below_for += real_delta
	else:
		_below_for = 0.0
	if _below_for >= hold_seconds:
		triggered = true
		return true
	return false


func reset() -> void:
	triggered = false
	_below_for = 0.0
