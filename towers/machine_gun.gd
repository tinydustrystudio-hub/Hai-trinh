class_name MachineGun
extends Tower
## Súng Máy (GDD mục 3.3): bắn tức thì theo tốc bắn, mỗi phát trúng ngay mục tiêu; vệt đạn vẽ bằng BulletRenderer.

## Hệ số sát thương hiện tại (MEGA, làm mát ở bước 10). 1 lúc bình thường.
var damage_multiplier: float = 1.0
## Số phát đã bắn (để thử và để nạp Quá tải về sau).
var shots_fired: int = 0

var _bullets: BulletRenderer
var _cooldown: float = 0.0


func _setup_effects(effects: Node) -> void:
	_bullets = effects.get_node_or_null("BulletRenderer") as BulletRenderer if effects != null else null


func fire(delta: float) -> void:
	_cooldown -= delta
	if target == null:
		# Không có mục tiêu thì không tích phát dồn.
		_cooldown = maxf(_cooldown, 0.0)
		return
	var interval: float = 1.0 / maxf(stats().fire_rate, 0.001)
	# Có thể bắn nhiều phát trong một nhịp dài (tua ×2, máy chậm) mà vẫn đúng tốc bắn.
	while _cooldown <= 0.0 and target != null:
		_cooldown += interval
		shoot(target)
		if not target.active:
			target = null


## Một phát trúng mục tiêu: sát thương × hệ số, sau giáp (Enemy tự trừ giáp).
func shoot(enemy: Enemy) -> void:
	shots_fired += 1
	var hit_point: Vector3 = enemy.global_position + Vector3(0.0, 0.4, 0.0)
	if _bullets != null:
		_bullets.add_tracer(muzzle_position(), hit_point)
	_pool.damage(enemy, stats().damage * damage_multiplier)
