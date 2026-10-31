class_name Overload
extends RefCounted
## Thanh Quá tải của một lô cốt (GDD mục 3.1; kế hoạch mục 5.2): Nạp → Sẵn sàng → MEGA → Làm mát → Nạp.
## Thanh không tụt khi lô cốt ngừng bắn và giữ nguyên khi nâng cấp. Trả hệ số sát thương (hoặc hiệu ứng):
## mega_multiplier khi đang MEGA, cooldown_fire_power khi đang làm mát, 1 lúc bình thường.

signal ready
signal mega_started
signal mega_ended

enum State { CHARGING, READY, MEGA, COOLDOWN }

var state: State = State.CHARGING
## 0–1 khi đang nạp; 1 khi sẵn sàng.
var charge: float = 0.0
## Số giây còn lại của MEGA hoặc làm mát.
var time_left: float = 0.0

var _data: TowerData


func _init(data: TowerData) -> void:
	_data = data


## Cộng vào thanh (chỉ khi đang nạp). Đầy thì chuyển sang Sẵn sàng.
func add_charge(amount: float) -> void:
	if state != State.CHARGING or amount <= 0.0:
		return
	charge = minf(charge + amount, 1.0)
	if charge >= 1.0 - 0.000001:
		charge = 1.0
		state = State.READY
		ready.emit()


func is_ready() -> bool:
	return state == State.READY


## Kích MEGA khi đã sẵn sàng; trả true nếu đã kích.
func activate() -> bool:
	if state != State.READY:
		return false
	state = State.MEGA
	time_left = _data.mega_duration
	mega_started.emit()
	return true


func advance(delta: float) -> void:
	match state:
		State.MEGA:
			time_left -= delta
			if time_left <= 0.0:
				var spill: float = -time_left
				state = State.COOLDOWN
				time_left = _data.cooldown_duration - spill
				mega_ended.emit()
				if time_left <= 0.0:
					_finish_cooldown()
		State.COOLDOWN:
			time_left -= delta
			if time_left <= 0.0:
				_finish_cooldown()


## Hệ số hiện tại.
func multiplier() -> float:
	match state:
		State.MEGA:
			return _data.mega_multiplier
		State.COOLDOWN:
			return _data.cooldown_fire_power
	return 1.0


## Phần hiện của thanh (0–1) để vẽ: nạp thì là mức nạp; MEGA và làm mát là phần thời gian còn lại.
func display_fill() -> float:
	match state:
		State.MEGA:
			return clampf(time_left / maxf(_data.mega_duration, 0.001), 0.0, 1.0)
		State.COOLDOWN:
			return clampf(time_left / maxf(_data.cooldown_duration, 0.001), 0.0, 1.0)
	return charge


## Lượng nạp mỗi phát trúng của lô cốt bắn liên tục: đầy sau đúng overload_charge_seconds giây bắn ở fire_rate.
static func charge_per_hit(charge_seconds: float, fire_rate: float) -> float:
	return 1.0 / maxf(charge_seconds * fire_rate, 0.001)


## Lượng nạp mỗi giây của Lô Cốt Keo: (số địch đang bị keo làm chậm, tối đa 3, chia 3) ÷ thời gian nạp.
static func glue_charge_rate(slowed: int, charge_seconds: float) -> float:
	return (float(mini(slowed, 3)) / 3.0) / maxf(charge_seconds, 0.001)


func _finish_cooldown() -> void:
	state = State.CHARGING
	charge = 0.0
	time_left = 0.0
