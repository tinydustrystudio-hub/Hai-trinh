class_name EnemyPool
extends Node3D
## Tạo sẵn POOL_SIZE địch; lấy ra khi sinh, trả lại khi bị hạ hoặc lọt. Mọi địch được cập nhật
## trong một vòng lặp ở đây (không có _process riêng). Giữ danh sách địch đang hoạt động cho lô cốt tra cứu.
## Vẽ thanh máu, bóng tròn và vệt bọt đuôi tàu của mọi địch bằng ba MultiMesh (ba lệnh vẽ).

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
const WAKE_SHADER: Shader = preload("res://enemies/wake.gdshader")
## Vệt bọt dài gấp chừng này lần thân tàu, rộng gấp chừng này lần.
const WAKE_LENGTH: float = 2.8
const WAKE_WIDTH: float = 1.7
## Số đoạn chia theo chiều dài của mảnh vệt bọt để vertex shader uốn cong mượt.
const WAKE_SUBDIVISIONS: int = 12
## Độ cong nhỏ hơn mức này coi như vệt thẳng (tránh chia cho số rất nhỏ).
const WAKE_STRAIGHT: float = 0.0001
## Bóng tròn rộng gấp chừng này lần thân tàu, dời theo hướng ngược nắng.
const SHADOW_SCALE: float = 1.25
const SHADOW_OFFSET: float = 0.5
const EFFECT_Y: float = 0.18

## Địch đang hoạt động. Không thêm bớt từ bên ngoài.
var active: Array[Enemy] = []
var ocean: Ocean = null

var _free: Array[Enemy] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _bars: MultiMeshInstance3D
var _wakes: MultiMeshInstance3D
var _shadows: MultiMeshInstance3D
var _shadow_offset: Vector3 = Vector3.ZERO
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
	_build_effects()


## Hướng nắng của bản đồ: bóng tròn dời về phía ngược nắng.
func configure_effects(sun_direction: Vector3) -> void:
	var away: Vector3 = -Vector3(sun_direction.x, 0.0, sun_direction.z)
	_shadow_offset = away.normalized() * SHADOW_OFFSET if away.length() > 0.001 else Vector3.ZERO


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
	if _wakes != null:
		_update_bars()
		_update_effects()


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
	_update_effects()


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


func _build_effects() -> void:
	var wake_mesh: PlaneMesh = PlaneMesh.new()
	wake_mesh.size = Vector2(1.0, 1.0)
	wake_mesh.subdivide_depth = WAKE_SUBDIVISIONS
	var wake_material: ShaderMaterial = ShaderMaterial.new()
	wake_material.shader = WAKE_SHADER
	wake_material.set_shader_parameter(&"noise_tex", Ocean.foam_noise())
	wake_material.render_priority = -1
	wake_mesh.material = wake_material
	_wakes = _effect_instance("Wakes", wake_mesh, POOL_SIZE, true)
	# Shader dời đỉnh ra xa mesh gốc: đặt khung bao đủ rộng để không bị cắt nhầm.
	_wakes.multimesh.custom_aabb = AABB(Vector3(-500, -10, -500), Vector3(1000, 20, 1000))
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(0.0, 0.02, 0.06, 0.55))
	gradient.set_color(1, Color(0.0, 0.02, 0.06, 0.0))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 64
	texture.height = 64
	var shadow_material: StandardMaterial3D = StandardMaterial3D.new()
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	shadow_material.albedo_texture = texture
	shadow_material.render_priority = -2
	var shadow_mesh: PlaneMesh = PlaneMesh.new()
	shadow_mesh.size = Vector2(1.0, 1.0)
	shadow_mesh.material = shadow_material
	_shadows = _effect_instance("Shadows", shadow_mesh, POOL_SIZE, false)


func _effect_instance(node_name: String, mesh: Mesh, count: int, custom_data: bool) -> MultiMeshInstance3D:
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = custom_data
	multimesh.mesh = mesh
	multimesh.instance_count = count
	multimesh.visible_instance_count = 0
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance


func _update_effects() -> void:
	var wakes: MultiMesh = _wakes.multimesh
	var shadows: MultiMesh = _shadows.multimesh
	var count: int = active.size()
	var wake_count: int = 0
	for i: int in count:
		var enemy: Enemy = active[i]
		var length: float = enemy.data.size_cells * MapLayout.UNITS_PER_CELL
		var forward: Vector3 = enemy.forward
		var yaw: Basis = Basis.looking_at(forward, Vector3.UP)
		var ground: Vector3 = Vector3(enemy.position.x, EFFECT_Y, enemy.position.z)
		var stern: float = length * 0.45
		# Vệt chỉ dài bằng quãng tàu đã đi, để không vẽ ra ngoài đầu luồng.
		var wake_length: float = minf(length * WAKE_LENGTH, enemy.distance - stern)
		if wake_length > 0.5:
			var back: Vector3 = enemy.lane.direction_at(enemy.distance - stern - wake_length)
			var curvature: float = wake_curvature(yaw, back, wake_length)
			wakes.set_instance_transform(wake_count, Transform3D(yaw, ground - forward * stern))
			wakes.set_instance_custom_data(wake_count, Color(curvature, length * 0.5 * WAKE_WIDTH, wake_length, 0.0))
			wake_count += 1
		var size: float = length * SHADOW_SCALE
		shadows.set_instance_transform(i, Transform3D(yaw.scaled_local(Vector3(size * 0.7, 1.0, size)), ground + _shadow_offset + Vector3(0.0, -0.02, 0.0)))
	wakes.visible_instance_count = wake_count
	shadows.visible_instance_count = count


## Độ cong (radian mỗi đơn vị) để vệt bọt dài wake_length uốn từ hướng đuôi tàu (theo khung yaw của tàu)
## tới hướng của đường tàu đã đi ở cuối vệt (back_forward). Khớp với wake.gdshader.
static func wake_curvature(yaw: Basis, back_forward: Vector3, wake_length: float) -> float:
	var behind: Vector3 = -back_forward
	var angle: float = atan2(behind.dot(yaw.x.normalized()), behind.dot(yaw.z.normalized()))
	return angle / maxf(wake_length, 0.001)


## Điểm của vệt bọt trong khung của tàu (gốc ở đuôi tàu, +z về phía sau, +x sang phải):
## cách đuôi s đơn vị theo đường vệt, lệch ngang x. Cùng công thức với vertex shader của wake.gdshader.
static func wake_point(curvature: float, s: float, x: float) -> Vector3:
	var theta: float = curvature * s
	var center: Vector3
	if absf(curvature) < WAKE_STRAIGHT:
		center = Vector3(0.5 * curvature * s * s, 0.0, s)
	else:
		center = Vector3((1.0 - cos(theta)) / curvature, 0.0, sin(theta) / curvature)
	return center + Vector3(cos(theta), 0.0, -sin(theta)) * x
