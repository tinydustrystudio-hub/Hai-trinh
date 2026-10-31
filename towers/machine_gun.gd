class_name MachineGun
extends Tower
## Súng Máy (GDD mục 3.3): bắn tức thì theo tốc bắn, mỗi phát trúng ngay mục tiêu; vệt đạn vẽ bằng BulletRenderer.
## Nhánh 5A Mưa Đạn: mỗi loạt bắn tới 3 mục tiêu; kỹ năng Quét Ngang cứ 6 giây quét một hình quạt phía trước.
## Nhánh 5B Xuyên Giáp: bỏ qua 70% giáp; kỹ năng Đạn Lõi Thép cứ phát thứ 4 gây ×3 lên địch giáp từ bậc 3.

## Hệ số sát thương thêm (thử nghiệm, kỹ năng khác về sau). Quá tải nhân riêng.
var damage_multiplier: float = 1.0
## Số phát đã bắn (để thử và để nạp Quá tải về sau).
var shots_fired: int = 0
var sweeps: int = 0

var _bullets: BulletRenderer
var _cooldown: float = 0.0
var _sweep_left: float = 0.0
## Mục tiêu phụ của Mưa Đạn, cấp phát một lần.
var _extra_targets: Array[Enemy] = []


func _setup_effects(effects: Node) -> void:
	_bullets = effects.get_node_or_null("BulletRenderer") as BulletRenderer if effects != null else null


func _on_branch_chosen(_lanes: Array[Lane]) -> void:
	_sweep_left = branch.sweep_interval


func fire(delta: float) -> void:
	_cooldown -= delta
	_update_sweep(delta)
	if target == null:
		# Không có mục tiêu thì không tích phát dồn.
		_cooldown = maxf(_cooldown, 0.0)
		return
	var interval: float = 1.0 / maxf(stats().fire_rate, 0.001)
	# Có thể bắn nhiều phát trong một nhịp dài (tua ×2, máy chậm) mà vẫn đúng tốc bắn.
	while _cooldown <= 0.0 and target != null:
		_cooldown += interval
		volley()
		if not target.active:
			target = null


## Một loạt: một phát vào mục tiêu chính, cộng thêm mục tiêu phụ nếu nhánh bắn nhiều mục tiêu.
func volley() -> void:
	var count: int = branch.targets_per_shot if branch != null else 1
	if count > 1:
		_pick_extra_targets(count - 1)
		for extra: Enemy in _extra_targets:
			shoot(extra)
	if target != null and target.active:
		shoot(target)
		# Nạp Quá tải theo loạt bắn vào mục tiêu chính: đầy sau đúng 14 giây bắn liên tục (kế hoạch mục 5.4).
		overload.add_charge(Overload.charge_per_hit(data.overload_charge_seconds, stats().fire_rate))


## Một phát trúng enemy: sát thương × hệ số, sau giáp (Enemy tự trừ giáp, Xuyên Giáp bỏ qua một phần).
func shoot(enemy: Enemy) -> void:
	shots_fired += 1
	var amount: float = stats().damage * damage_multiplier * overload_multiplier()
	var armor_ignore: float = 0.0
	if branch != null:
		armor_ignore = branch.armor_ignore
		if is_core_round(shots_fired, enemy):
			amount *= branch.core_round_multiplier
	if _bullets != null:
		_bullets.add_tracer(muzzle_position(), enemy.global_position + Vector3(0.0, 0.4, 0.0))
	_pool.damage(enemy, amount, armor_ignore)


## Phát thứ shot_number có là Đạn Lõi Thép trúng địch giáp dày không.
func is_core_round(shot_number: int, enemy: Enemy) -> bool:
	if branch == null or branch.core_round_every <= 0:
		return false
	return shot_number % branch.core_round_every == 0 and enemy.armor_tier() >= branch.core_round_min_armor_tier


## Quét Ngang: gây sát thương một phát lên mọi địch trong hình quạt hướng về mục tiêu (hoặc hướng nòng).
func sweep() -> int:
	sweeps += 1
	var origin: Vector3 = global_position
	var facing: Vector3 = muzzle_position() - origin
	if target != null:
		facing = target.global_position - origin
	facing.y = 0.0
	if facing.length() < 0.001:
		return 0
	facing = facing.normalized()
	var half_angle: float = deg_to_rad(branch.sweep_angle_degrees) * 0.5
	var reach: float = range_units()
	var amount: float = stats().damage * branch.sweep_damage_multiplier * damage_multiplier * overload_multiplier()
	var hits: int = 0
	for i: int in range(_pool.active.size() - 1, -1, -1):
		var enemy: Enemy = _pool.active[i]
		if not data.target_layers.has(enemy.data.layer):
			continue
		var to_enemy: Vector3 = enemy.global_position - origin
		to_enemy.y = 0.0
		var distance: float = to_enemy.length()
		if distance > reach or distance < 0.001:
			continue
		if facing.angle_to(to_enemy / distance) > half_angle:
			continue
		if _bullets != null:
			_bullets.add_tracer(muzzle_position(), enemy.global_position + Vector3(0.0, 0.4, 0.0))
		_pool.damage(enemy, amount)
		hits += 1
	return hits


func _update_sweep(delta: float) -> void:
	if branch == null or branch.sweep_interval <= 0.0:
		return
	_sweep_left -= delta
	if _sweep_left > 0.0:
		return
	if target == null:
		# Chờ có địch mới quét, không quét vào nước trống.
		_sweep_left = 0.0
		return
	_sweep_left += branch.sweep_interval
	sweep()


func _pick_extra_targets(count: int) -> void:
	_extra_targets.clear()
	var origin: Vector3 = global_position
	var range_squared: float = range_units() * range_units()
	for enemy: Enemy in _pool.active:
		if _extra_targets.size() >= count:
			break
		if enemy == target or not Targeting.can_hit(enemy, origin, range_squared, data.target_layers):
			continue
		_extra_targets.append(enemy)
