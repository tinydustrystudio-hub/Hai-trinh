extends Node
## Autoload Events: bus tín hiệu chung của trận (kế hoạch tháng 1, mục 5.3).
## Các hệ thống phát và nghe ở đây, không gọi thẳng nhau.

@warning_ignore_start("unused_signal")
signal enemy_killed(enemy: Enemy, reward: int)
signal enemy_leaked(enemy: Enemy, damage: int)
signal steel_changed(value: int)
signal buoyancy_changed(value: int, max_value: int)
signal wave_started(index: int, total: int)
signal wave_cleared(index: int)
## Báo đợt sắp tới: chỉ số đợt, các luồng có địch, số giây còn lại.
signal wave_incoming(index: int, lanes: PackedInt32Array, seconds: float)
signal tower_built(tower: Node3D)
signal tower_upgraded(tower: Node3D)
signal tower_sold(tower: Node3D)
signal tower_moved(tower: Node3D)
## Một phát bắn của lô cốt (để phát tiếng; phát nhiều, đừng làm việc nặng khi nghe).
signal tower_fired(tower: Node3D)
signal overload_ready(tower: Node3D)
signal mega_started(tower: Node3D)
signal mega_ended(tower: Node3D)
signal battle_ended(won: bool)
## Sét đánh; thunder_delay là số giây tới khi tiếng sấm tới.
signal lightning_struck(thunder_delay: float)
## Một nút giao diện vừa được bấm (để phát tiếng bấm).
signal ui_clicked
@warning_ignore_restore("unused_signal")
