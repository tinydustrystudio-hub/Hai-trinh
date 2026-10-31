class_name Haptics
extends Node
## Rung máy (góp ý 3 của đạo diễn): khi tàu địch đâm vào đảo chính, khi nổ MEGA và khi tàu trùm nổ.
## Dùng Input.vibrate_handheld (Android; trình duyệt có navigator.vibrate). Tắt khi Settings.vibration_enabled
## là false. Địch lọt dồn dập thì chỉ rung cách nhau MIN_GAP giây để không rung liên hồi.

enum Kind { LEAK, MEGA, BOSS }

const DURATION_MS: Dictionary[Kind, int] = { Kind.LEAK: 70, Kind.MEGA: 200, Kind.BOSS: 450 }
const AMPLITUDE: Dictionary[Kind, float] = { Kind.LEAK: 0.55, Kind.MEGA: 0.85, Kind.BOSS: 1.0 }
const MIN_GAP: Dictionary[Kind, float] = { Kind.LEAK: 0.3, Kind.MEGA: 0.25, Kind.BOSS: 0.0 }

## Số lần đã rung mỗi loại (để thử).
var pulses: Dictionary[Kind, int] = { Kind.LEAK: 0, Kind.MEGA: 0, Kind.BOSS: 0 }

var _last: Dictionary[Kind, float] = { Kind.LEAK: -1.0, Kind.MEGA: -1.0, Kind.BOSS: -1.0 }


func _ready() -> void:
	Events.enemy_leaked.connect(func(_enemy: Enemy, _damage: int) -> void: pulse(Kind.LEAK))
	Events.mega_started.connect(func(_tower: Node3D) -> void: pulse(Kind.MEGA))
	Events.enemy_killed.connect(_on_enemy_killed)


## Rung một lần nếu đã đủ khoảng cách với lần trước cùng loại; trả true nếu đã rung.
func pulse(kind: Kind) -> bool:
	if not Settings.vibration_enabled:
		return false
	var now: float = float(Time.get_ticks_msec()) / 1000.0
	if _last[kind] >= 0.0 and now - _last[kind] < MIN_GAP[kind]:
		return false
	_last[kind] = now
	pulses[kind] += 1
	Input.vibrate_handheld(DURATION_MS[kind], AMPLITUDE[kind])
	return true


func _on_enemy_killed(enemy: Enemy, _reward: int) -> void:
	if enemy != null and enemy.data != null and enemy.data.is_boss:
		pulse(Kind.BOSS)
