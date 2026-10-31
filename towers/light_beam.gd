class_name LightBeam
extends Tower
## Lô Cốt Tia Sáng (góp ý 4, mục 9): phóng một chùm sáng hội tụ liên tục vào mục tiêu. Sát thương mỗi giây tăng dần
## khi giữ chùm trên cùng một mục tiêu (tối đa +beam_ramp_bonus sau beam_ramp_seconds giây) và bỏ qua một phần giáp;
## đổi mục tiêu thì phải hội tụ lại từ đầu. Tia vẽ bằng BeamRenderer (một lệnh vẽ cho mọi tia).
## Nạp Quá tải theo thời gian chiếu: đầy sau overload_charge_seconds giây chiếu liên tục.

## Cứ chừng này giây chiếu thì báo một lần cho âm thanh (tia liên tục không có từng phát).
const FIRE_EVENT_INTERVAL: float = 0.25

## Thời gian đã giữ tia trên mục tiêu hiện tại, giây.
var focus_time: float = 0.0
## Tổng sát thương đã gây (để thử).
var damage_dealt: float = 0.0

var _focus_target: Enemy = null
## Số thứ tự sinh của mục tiêu đang giữ tia (địch trong pool được dùng lại nên không thể chỉ so tham chiếu).
var _focus_serial: int = -1
var _event_left: float = 0.0
var _beam_to: Vector3 = Vector3.ZERO
var _beaming: bool = false


func fire(delta: float) -> void:
	_beaming = false
	if target == null or not target.active:
		focus_time = 0.0
		_focus_target = null
		return
	if target != _focus_target or target.serial != _focus_serial:
		_focus_target = target
		_focus_serial = target.serial
		focus_time = 0.0
	var level: TowerLevel = stats()
	var amount: float = damage_for(level, focus_time) * overload_multiplier() * delta
	focus_time += delta
	_beaming = true
	_beam_to = target.global_position + Vector3(0.0, 0.4, 0.0)
	var victim: Enemy = target
	damage_dealt += _pool.damage(victim, amount, level.beam_armor_ignore)
	overload.add_charge(delta / maxf(data.overload_charge_seconds, 0.001))
	_event_left -= delta
	if _event_left <= 0.0:
		_event_left = FIRE_EVENT_INTERVAL
		Events.tower_fired.emit(self)
	if not victim.active:
		target = null


## Sát thương mỗi giây sau focus giây giữ tia: tăng tuyến tính từ 1× tới (1 + beam_ramp_bonus)×.
static func damage_for(level: TowerLevel, focus: float) -> float:
	var ramp: float = clampf(focus / maxf(level.beam_ramp_seconds, 0.001), 0.0, 1.0)
	return level.damage_per_second * (1.0 + level.beam_ramp_bonus * ramp)


## Hệ số hội tụ hiện tại (0–1), để vẽ tia sáng hơn khi đã hội tụ.
func focus_ratio() -> float:
	return clampf(focus_time / maxf(stats().beam_ramp_seconds, 0.001), 0.0, 1.0)


func is_beaming() -> bool:
	return _beaming


## Ghi tia vào BeamRenderer (gọi mỗi nhịp sau tick, giữa begin() và finish()).
func draw_beam(renderer: BeamRenderer) -> void:
	if _beaming and renderer != null:
		renderer.draw(muzzle_position(), _beam_to, focus_ratio(), overload.state == Overload.State.MEGA)
