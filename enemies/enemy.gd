class_name Enemy
extends Node3D
## Một địch. Đi theo luồng bằng quãng đường (không dùng vật lý), nhận sát thương sau giáp,
## nhấp nhô theo sóng, báo bị hạ hoặc lọt qua Events. EnemyPool tạo sẵn và gọi advance() mỗi khung.

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
## Hệ số tốc độ do hiệu ứng (làm chậm ở bước 8). 1 = tốc độ gốc.
var speed_multiplier: float = 1.0
## Địch do WaveSpawner sinh (tính vào việc dọn sạch đợt); địch sinh từ bảng debug thì không.
var counts_for_wave: bool = false
## Hướng đi hiện tại trên mặt nước (đã chuẩn hóa), cập nhật mỗi lần tàu đi.
var forward: Vector3 = Vector3.FORWARD

var _body: MeshInstance3D
var _bob_phase: float = 0.0


func _init() -> void:
	_body = MeshInstance3D.new()
	_body.name = "Body"
	_body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.material_override = EnemyMeshes.material()
	add_child(_body)
	visible = false
	set_process(false)


## Đưa địch vào trận ở đầu luồng.
func spawn(enemy_data: EnemyData, on_lane: Lane, offset: float, bob_phase: float, start_distance: float = 0.0) -> void:
	data = enemy_data
	lane = on_lane
	distance = clampf(start_distance, 0.0, on_lane.length())
	health = enemy_data.max_health
	lateral_offset = offset
	speed_multiplier = 1.0
	counts_for_wave = false
	_bob_phase = bob_phase
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
func advance(delta: float, wave_height: float) -> bool:
	distance += data.speed_units() * speed_multiplier * delta
	if distance >= lane.length():
		distance = lane.length()
		return true
	_place(wave_height)
	return false


## Nhận sát thương thô (đã nhân hệ số MEGA); trả sát thương thật sau giáp.
func take_damage(amount: float) -> float:
	if not active:
		return 0.0
	var dealt: float = minf(damage_after_armor(amount, data.armor), health)
	health -= dealt
	return dealt


func is_dead() -> bool:
	return health <= 0.0


func health_ratio() -> float:
	return clampf(health / data.max_health, 0.0, 1.0) if data != null else 0.0


## Sát thương nhận = sát thương × (1 − giáp) (kế hoạch mục 5.4).
static func damage_after_armor(amount: float, armor: float) -> float:
	return maxf(amount, 0.0) * (1.0 - clampf(armor, 0.0, 1.0))


func _place(wave_height: float) -> void:
	forward = lane.direction_at(distance)
	var side: Vector3 = Vector3(-forward.z, 0.0, forward.x)
	var point: Vector3 = lane.position_at(distance) + side * lateral_offset
	point.y = wave_height
	position = point
	var roll: float = sin(_bob_phase + distance * 0.7) * ROLL_AMOUNT
	basis = Basis.looking_at(forward, Vector3.UP).rotated(forward, roll)
