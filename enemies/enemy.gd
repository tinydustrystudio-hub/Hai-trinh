class_name Enemy
extends Node3D
## Một địch. Đi theo luồng bằng quãng đường (không dùng vật lý), nhận sát thương sau giáp,
## nhấp nhô theo sóng, báo bị hạ hoặc lọt qua Events. EnemyPool tạo sẵn và gọi advance() mỗi khung.

const RULES: CombatRules = preload("res://data/combat_rules.tres")

## Biên độ lắc ngang theo sóng, radian.
const ROLL_AMOUNT: float = 0.12

var data: EnemyData
var lane: Lane
## Quãng đường đã đi trên luồng, đơn vị Godot.
var distance: float = 0.0
var health: float = 0.0
var active: bool = false
## Lệch sang ngang so với tâm luồng, để một đàn không chồng lên nhau.
var lateral_offset: float = 0.0
## Hệ số tốc độ do hiệu ứng làm chậm, tính lại mỗi nhịp từ status. 1 = tốc độ gốc.
var speed_multiplier: float = 1.0
## Làm chậm từ các lô cốt (cộng dồn có trần).
var status: StatusEffects = StatusEffects.new()
## Địch do WaveSpawner sinh (tính vào việc dọn sạch đợt); địch sinh từ bảng debug thì không.
var counts_for_wave: bool = false
## Hướng đi hiện tại trên mặt nước (đã chuẩn hóa), cập nhật mỗi lần tàu đi.
var forward: Vector3 = Vector3.FORWARD
## Số thứ tự sinh ra, để phân xử khi hai địch đứng cùng chỗ.
var serial: int = 0

var _body: MeshInstance3D
var _bob_phase: float = 0.0
## Đường lượn riêng (góp ý 5): biên độ, hai tần số và hai pha; biên độ 0 là đi đúng giữa luồng.
var _wander_amplitude: float = 0.0
var _wander_freq: Vector2 = Vector2.ONE
var _wander_phase: Vector2 = Vector2.ZERO


func _init() -> void:
	_body = MeshInstance3D.new()
	_body.name = "Body"
	_body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.material_override = EnemyMeshes.material()
	add_child(_body)
	visible = false
	set_process(false)


## Đặt đường lượn riêng cho địch này từ bộ số ngẫu nhiên rng và luật chung RULES.
func set_wander(rng: RandomNumberGenerator) -> void:
	_wander_amplitude = RULES.wander_amplitude * rng.randf_range(0.55, 1.0)
	var first: float = TAU / rng.randf_range(RULES.wander_wavelength_min, RULES.wander_wavelength_max)
	var second: float = TAU / rng.randf_range(RULES.wander_wavelength_min * 0.5, RULES.wander_wavelength_max * 0.7)
	_wander_freq = Vector2(first, second)
	_wander_phase = Vector2(rng.randf() * TAU, rng.randf() * TAU)


## Độ lệch ngang do đường lượn tại quãng đường dist, và độ dốc của nó (đạo hàm theo dist).
func wander_at(dist: float) -> Vector2:
	var a: float = _wander_freq.x * dist + _wander_phase.x
	var b: float = _wander_freq.y * dist + _wander_phase.y
	var offset: float = _wander_amplitude * (0.65 * sin(a) + 0.35 * sin(b))
	var slope: float = _wander_amplitude * (0.65 * _wander_freq.x * cos(a) + 0.35 * _wander_freq.y * cos(b))
	return Vector2(offset, slope)


## Hướng mũi tàu khi ở quãng đường dist (đã tính đường lượn).
func heading_at(dist: float) -> Vector3:
	var along: Vector3 = lane.direction_at(dist)
	var side: Vector3 = Vector3(-along.z, 0.0, along.x)
	return (along + side * wander_at(dist).y).normalized()


## Bỏ đường lượn: đi đúng giữa luồng (cho test và cảnh thử cần vị trí chính xác).
func clear_wander() -> void:
	_wander_amplitude = 0.0


func wander_amplitude() -> float:
	return _wander_amplitude


## Đưa địch vào trận ở đầu luồng.
func spawn(enemy_data: EnemyData, on_lane: Lane, offset: float, bob_phase: float, start_distance: float = 0.0) -> void:
	data = enemy_data
	lane = on_lane
	distance = clampf(start_distance, 0.0, on_lane.length())
	health = enemy_data.max_health
	lateral_offset = offset
	speed_multiplier = 1.0
	status.clear()
	counts_for_wave = false
	_bob_phase = bob_phase
	_wander_amplitude = 0.0
	_body.mesh = EnemyMeshes.mesh_for(enemy_data)
	active = true
	visible = true
	_place(0.0)


func despawn() -> void:
	active = false
	visible = false
	data = null
	lane = null


## Đi tiếp delta giây. Trả true nếu vừa tới cuối luồng (lọt vào đảo).
## limit là quãng đường tối đa được tới (không đâm vào địch đi trước); không bao giờ lùi.
func advance(delta: float, wave_height: float, limit: float = INF) -> bool:
	speed_multiplier = status.speed_factor_now(data.is_boss)
	status.advance(delta)
	distance = maxf(distance, minf(distance + data.speed_units() * speed_multiplier * delta, limit))
	if distance >= lane.length():
		distance = lane.length()
		return true
	_place(wave_height)
	return false


## Nhận sát thương thô (đã nhân hệ số MEGA); armor_ignore là tỉ lệ giáp bị bỏ qua (Xuyên Giáp).
## Trả sát thương thật sau giáp.
func take_damage(amount: float, armor_ignore: float = 0.0) -> float:
	if not active:
		return 0.0
	var armor: float = current_armor() * (1.0 - clampf(armor_ignore, 0.0, 1.0))
	var dealt: float = minf(damage_after_armor(amount, armor), health)
	health -= dealt
	return dealt


## Giáp đang có, sau Keo Ăn Mòn và Bóc Giáp.
func current_armor() -> float:
	return status.effective_armor(data.armor, RULES)


## Bậc giáp gốc theo GDD mục 3.1.
func armor_tier() -> int:
	return RULES.tier_of(data.armor)


func is_dead() -> bool:
	return health <= 0.0


func health_ratio() -> float:
	return clampf(health / data.max_health, 0.0, 1.0) if data != null else 0.0


## Sát thương nhận = sát thương × (1 − giáp) (kế hoạch mục 5.4).
static func damage_after_armor(amount: float, armor: float) -> float:
	return maxf(amount, 0.0) * (1.0 - clampf(armor, 0.0, 1.0))


func _place(wave_height: float) -> void:
	var along: Vector3 = lane.direction_at(distance)
	var side: Vector3 = Vector3(-along.z, 0.0, along.x)
	var wander: Vector2 = wander_at(distance)
	# Mũi tàu xoay theo đường lượn: đi lệch sang bên thì quay nhẹ về phía đó.
	forward = (along + side * wander.y).normalized()
	var point: Vector3 = lane.position_at(distance) + side * (lateral_offset + wander.x)
	point.y = wave_height
	position = point
	var roll: float = sin(_bob_phase + distance * 0.7) * ROLL_AMOUNT
	basis = Basis.looking_at(forward, Vector3.UP).rotated(forward, roll)
