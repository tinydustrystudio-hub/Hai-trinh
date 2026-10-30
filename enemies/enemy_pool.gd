class_name EnemyPool
extends Node3D
## Tạo sẵn POOL_SIZE địch; lấy ra khi sinh, trả lại khi bị hạ hoặc lọt. Mọi địch được cập nhật
## trong một vòng lặp ở đây (không có _process riêng). Giữ danh sách địch đang hoạt động cho lô cốt tra cứu.
## Vẽ thanh máu của mọi địch bằng một MultiMesh.

const POOL_SIZE: int = 80
const ENEMY_SCENE: PackedScene = preload("res://enemies/enemy.tscn")
## Đàn địch lệch ngang ngẫu nhiên trong khoảng ±LATERAL_SPREAD đơn vị.
const LATERAL_SPREAD: float = 0.7
const BAR_WIDTH: float = 2.0
const BAR_HEIGHT: float = 0.28
const BAR_LIFT: float = 2.2
const BAR_BACK_COLOR: Color = Color(0.1, 0.1, 0.1, 0.8)
const BAR_FULL_COLOR: Color = Color(0.3, 0.95, 0.35)
const BAR_LOW_COLOR: Color = Color(1.0, 0.3, 0.2)

## Địch đang hoạt động. Không thêm bớt từ bên ngoài.
var active: Array[Enemy] = []
var ocean: Ocean = null

var _free: Array[Enemy] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _bars: MultiMeshInstance3D
var _bar_basis: Basis = Basis.IDENTITY
var _time: float = 0.0


func _ready() -> void:
	_rng.seed = 1
	for i: int in POOL_SIZE:
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		enemy.name = "Enemy%d" % i
		add_child(enemy)
		_free.append(enemy)
	_build_bars()


## Lấy một địch từ pool và đặt trên luồng (mặc định ở đầu luồng). Hết chỗ thì trả null.
func acquire(data: EnemyData, lane: Lane, start_distance: float = 0.0) -> Enemy:
	if _free.is_empty():
		push_warning("EnemyPool: hết %d chỗ" % POOL_SIZE)
		return null
	var enemy: Enemy = _free.pop_back()
	var offset: float = _rng.randf_range(-LATERAL_SPREAD, LATERAL_SPREAD)
	enemy.spawn(data, lane, offset, _rng.randf_range(0.0, TAU), start_distance)
	active.append(enemy)
	return enemy


func release(enemy: Enemy) -> void:
	var index: int = active.find(enemy)
	if index == -1:
		return
	active.remove_at(index)
	enemy.despawn()
	_free.append(enemy)


## Số ngẫu nhiên dùng chung cho các việc sinh địch (giữ cố định hạt giống để chạy lại giống nhau).
func rng() -> RandomNumberGenerator:
	return _rng


func active_count() -> int:
	return active.size()


func free_count() -> int:
	return _free.size()


## Trả mọi địch về pool (chơi lại).
func clear() -> void:
	for i: int in range(active.size() - 1, -1, -1):
		release(active[i])


## Cho mọi địch đi tiếp delta giây; địch tới cuối luồng thì báo lọt và trả về pool.
func advance(delta: float) -> void:
	_time += delta
	for i: int in range(active.size() - 1, -1, -1):
		var enemy: Enemy = active[i]
		var height: float = 0.0
		if ocean != null:
			height = ocean.height_at(enemy.position.x, enemy.position.z, _time)
		if enemy.advance(delta, height):
			var damage: int = enemy.data.buoyancy_damage
			Events.enemy_leaked.emit(enemy, damage)
			release(enemy)
	_update_bars()


## Gây sát thương cho một địch; nếu hạ được thì báo và trả về pool. Trả sát thương thật.
func damage(enemy: Enemy, amount: float) -> float:
	var dealt: float = enemy.take_damage(amount)
	if enemy.active and enemy.is_dead():
		var reward: int = enemy.data.steel_reward
		Events.enemy_killed.emit(enemy, reward)
		release(enemy)
	return dealt


## Hướng thanh máu cho đúng camera (camera không xoay nên chỉ cần đặt một lần).
func face_camera(camera_basis: Basis) -> void:
	_bar_basis = camera_basis


func _build_bars() -> void:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	material.render_priority = 10
	quad.material = material
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = quad
	multimesh.instance_count = POOL_SIZE * 2
	multimesh.visible_instance_count = 0
	_bars = MultiMeshInstance3D.new()
	_bars.name = "HealthBars"
	_bars.multimesh = multimesh
	_bars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_bars)


func _update_bars() -> void:
	var multimesh: MultiMesh = _bars.multimesh
	var used: int = 0
	for enemy: Enemy in active:
		var ratio: float = enemy.health_ratio()
		if ratio >= 1.0:
			continue
		var top: Vector3 = enemy.position + Vector3(0.0, BAR_LIFT, 0.0)
		var back: Transform3D = Transform3D(_bar_basis.scaled_local(Vector3(BAR_WIDTH, BAR_HEIGHT, 1.0)), top)
		multimesh.set_instance_transform(used, back)
		multimesh.set_instance_color(used, BAR_BACK_COLOR)
		used += 1
		var fill_width: float = BAR_WIDTH * ratio
		var fill_center: Vector3 = top + _bar_basis.x * (fill_width - BAR_WIDTH) * 0.5
		var fill: Transform3D = Transform3D(_bar_basis.scaled_local(Vector3(fill_width, BAR_HEIGHT * 0.7, 1.0)), fill_center)
		multimesh.set_instance_transform(used, fill)
		multimesh.set_instance_color(used, BAR_LOW_COLOR.lerp(BAR_FULL_COLOR, ratio))
		used += 1
	multimesh.visible_instance_count = used
