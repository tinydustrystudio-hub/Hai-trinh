class_name BattleController
extends Node3D
## Điều khiển trận: nạp MapLayout và WaveData, dựng bản đồ, nối các hệ thống và chạy vòng đời trận
## (kế hoạch tháng 1, mục 4): Chuẩn bị → Đánh đợt ⇄ Nghỉ giữa đợt → Thắng (hết đợt) hoặc Thua (Độ Nổi về 0).
## Tạm dừng và tua nhanh chỉ đổi Engine.time_scale, không đổi trạng thái trận.

enum State { PREPARING, FIGHTING, RESTING, WON, LOST }

const LANE_SCRIPT: GDScript = preload("res://battle/map/lane.gd")
## Chạm cách tâm bệ trong khoảng này (tính theo bán kính bệ) vẫn tính là chạm trúng bệ.
const PAD_PICK_TOLERANCE: float = 1.4
const FAST_SPEED: float = 2.0
## Trần số địch cùng lúc (GDD mục 1.3, CLAUDE.md).
const MAX_ACTIVE_ENEMIES: int = 60
## Ở cảnh thử, địch mới xuất hiện rải trong đoạn đầu luồng này (tỉ lệ chiều dài luồng).
const STRESS_SPREAD: float = 0.85

@export var layout: MapLayout = preload("res://data/maps/north_dock_layout.tres")
@export var wave_data: WaveData = preload("res://data/waves/north_dock_waves.tres")

var state: State = State.PREPARING
var lanes: Array[Lane] = []
var selected_pad: TowerPad = null
var paused: bool = false
var speed: float = 1.0
## Cảnh thử hiệu năng: không có đợt, luôn giữ đủ MAX_ACTIVE_ENEMIES địch, đảo không chìm.
var stress_mode: bool = false
## Mili giây từ lúc chạy game tới lúc trận sẵn sàng (kế hoạch mục 7: không quá 3 giây).
var ready_msec: int = 0

var _enemy_types: Array[EnemyData] = []
## Đợt gần nhất đã cho luồng hiện rõ, để chỉ hiện một lần mỗi đợt.
var _revealed_wave: int = -1

@onready var ocean: Ocean = $Ocean
@onready var island: Island = $Island
@onready var lanes_root: Node3D = $Lanes
@onready var camera: BattleCamera = $BattleCamera
@onready var touch_input: TouchInput = $Systems/TouchInput
@onready var spawner: WaveSpawner = $Systems/WaveSpawner
@onready var buoyancy: Buoyancy = $Systems/Buoyancy
@onready var enemy_pool: EnemyPool = $EnemyPool
@onready var hud: Hud = $HUD
@onready var sun: DirectionalLight3D = $Sun
@onready var world_environment: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	build_map()
	enemy_pool.ocean = ocean
	enemy_pool.face_camera(camera.global_basis)
	touch_input.tapped.connect(_on_tapped)
	touch_input.drag_started.connect(camera.begin_drag)
	touch_input.drag_moved.connect(camera.drag_to)
	touch_input.drag_ended.connect(_on_drag_ended)
	touch_input.pinch_started.connect(camera.cancel_drag)
	touch_input.zoomed.connect(camera.zoom_by)
	spawner.spawn_requested.connect(_on_spawn_requested)
	spawner.wave_started.connect(_on_wave_started)
	spawner.wave_cleared.connect(_on_wave_cleared)
	spawner.wave_incoming.connect(_on_wave_incoming)
	spawner.all_waves_cleared.connect(_on_all_waves_cleared)
	buoyancy.changed.connect(_on_buoyancy_changed)
	buoyancy.depleted.connect(_on_buoyancy_depleted)
	Events.enemy_leaked.connect(_on_enemy_leaked)
	Events.enemy_killed.connect(_on_enemy_killed)
	hud.retry_requested.connect(retry)
	Settings.water_quality_changed.connect(_apply_quality)
	_apply_quality(Settings.water_quality)
	_enemy_types = enemy_types_in(wave_data)
	start_battle()
	ready_msec = Time.get_ticks_msec()


func _process(delta: float) -> void:
	TowerPad.animate_glow(float(Time.get_ticks_msec()) / 1000.0)
	step(delta)


## Chạy một nhịp của trận (delta đã nhân Engine.time_scale). Test gọi thẳng hàm này để tua nhanh.
func step(delta: float) -> void:
	if is_over() or delta <= 0.0:
		return
	spawner.advance(delta)
	if is_over():
		return
	enemy_pool.advance(delta)
	if stress_mode:
		spawn_burst(MAX_ACTIVE_ENEMIES - enemy_pool.active_count())
	island.set_tilt(buoyancy.tilt_degrees())


func start_battle() -> void:
	stress_mode = false
	enemy_pool.clear()
	select_pad(null)
	buoyancy.reset(layout.starting_buoyancy)
	state = State.PREPARING
	_revealed_wave = -1
	set_paused(false)
	set_speed(1.0)
	hud.hide_result()
	spawner.start(wave_data)


## Chuyển sang cảnh thử hiệu năng.
func enter_stress_mode() -> void:
	stress_mode = true
	spawner.stop()
	buoyancy.reset(1_000_000)
	hud.hide_result()
	state = State.FIGHTING
	spawn_burst(MAX_ACTIVE_ENEMIES)


## Sinh thêm tối đa count địch (không vượt MAX_ACTIVE_ENEMIES), loại và luồng ngẫu nhiên,
## rải dọc luồng. Trả số địch đã sinh. Dùng cho bảng debug và cảnh thử.
func spawn_burst(count: int) -> int:
	var room: int = mini(count, MAX_ACTIVE_ENEMIES - enemy_pool.active_count())
	if room <= 0 or _enemy_types.is_empty() or lanes.is_empty():
		return 0
	var rng: RandomNumberGenerator = enemy_pool.rng()
	var spawned: int = 0
	for i: int in room:
		var lane: Lane = lanes[rng.randi_range(0, lanes.size() - 1)]
		var data: EnemyData = _enemy_types[rng.randi_range(0, _enemy_types.size() - 1)]
		if enemy_pool.acquire(data, lane, rng.randf_range(0.0, lane.length() * STRESS_SPREAD)) == null:
			break
		spawned += 1
	return spawned


## Các loại địch xuất hiện trong dữ liệu đợt, không trùng.
static func enemy_types_in(data: WaveData) -> Array[EnemyData]:
	var result: Array[EnemyData] = []
	if data == null:
		return result
	for wave: Wave in data.waves:
		for group: SpawnGroup in wave.groups:
			if group.enemy != null and not result.has(group.enemy):
				result.append(group.enemy)
	return result


func is_over() -> bool:
	return state == State.WON or state == State.LOST


func set_paused(value: bool) -> void:
	paused = value
	_apply_time_scale()


func set_speed(value: float) -> void:
	speed = value
	_apply_time_scale()


func toggle_fast() -> void:
	set_speed(1.0 if speed > 1.0 else FAST_SPEED)


func retry() -> void:
	start_battle()


func build_map() -> void:
	island.build(layout)
	for lane: Lane in lanes:
		lane.queue_free()
	lanes.clear()
	for i: int in layout.lane_count():
		var lane: Lane = LANE_SCRIPT.new()
		var key: StringName = layout.lane_name_keys[i] if i < layout.lane_name_keys.size() else &""
		lane.setup(i, layout.lane_points[i], key)
		lanes_root.add_child(lane)
		lanes.append(lane)
	camera.configure(layout)
	_place_sun()
	enemy_pool.configure_effects(layout.sun_direction)


## Nắng chiếu công trình từ hướng sun_direction của bản đồ. Nước dùng cùng màu nắng nhưng vệt sáng
## của nước đặt sau đảo theo hướng nhìn của camera (GDD mục 8.6), không theo hướng nắng.
func _place_sun() -> void:
	var to_sun: Vector3 = layout.sun_direction.normalized()
	var up: Vector3 = Vector3.FORWARD if absf(to_sun.y) > 0.99 else Vector3.UP
	sun.basis = Basis.looking_at(-to_sun, up)
	ocean.configure(sun.light_color, layout.fortress_center, layout.fortress_radius, -camera.basis.z)


## Mức chất lượng thấp tắt glow (tốn thêm lượt vẽ toàn màn hình); nước tự đổi theo Settings.
func _apply_quality(quality: Ocean.Quality) -> void:
	world_environment.environment.glow_enabled = quality == Ocean.Quality.HIGH


func select_pad(pad: TowerPad) -> void:
	if selected_pad != null:
		selected_pad.selected = false
	selected_pad = pad
	if pad != null:
		pad.selected = true


func _end_battle(won: bool) -> void:
	if is_over():
		return
	state = State.WON if won else State.LOST
	spawner.stop()
	set_paused(false)
	set_speed(1.0)
	Events.battle_ended.emit(won)
	hud.show_result(won)


func _apply_time_scale() -> void:
	Engine.time_scale = 0.0 if paused else speed


func _on_spawn_requested(enemy: EnemyData, lane_index: int) -> void:
	var spawned: Enemy = enemy_pool.acquire(enemy, lanes[lane_index])
	if spawned == null:
		spawner.notify_enemy_removed()
	else:
		spawned.counts_for_wave = true


func _on_wave_started(index: int, total: int) -> void:
	state = State.FIGHTING
	Events.wave_started.emit(index, total)


func _on_wave_cleared(index: int) -> void:
	state = State.RESTING
	Events.wave_cleared.emit(index)


func _on_wave_incoming(index: int, lane_indices: PackedInt32Array, seconds: float) -> void:
	if index != _revealed_wave:
		_revealed_wave = index
		for lane_index: int in lane_indices:
			if lane_index < lanes.size():
				lanes[lane_index].reveal()
	Events.wave_incoming.emit(index, lane_indices, seconds)


func _on_all_waves_cleared() -> void:
	_end_battle(not buoyancy.is_sunk())


func _on_buoyancy_changed(value: int, max_value: int) -> void:
	Events.buoyancy_changed.emit(value, max_value)


func _on_buoyancy_depleted() -> void:
	_end_battle(false)


func _on_enemy_leaked(enemy: Enemy, damage: int) -> void:
	if enemy.counts_for_wave:
		spawner.notify_enemy_removed()
	if stress_mode:
		return
	if not is_over():
		buoyancy.take_leak(damage)


func _on_enemy_killed(enemy: Enemy, _reward: int) -> void:
	if enemy.counts_for_wave:
		spawner.notify_enemy_removed()


func _on_tapped(screen_position: Vector2) -> void:
	var point: Vector3 = camera.ground_point(screen_position, TowerPad.TOP_HEIGHT)
	var pad: TowerPad = island.pad_near(point, TowerPad.RADIUS * PAD_PICK_TOLERANCE)
	select_pad(pad if pad != selected_pad else null)


func _on_drag_ended(_screen_position: Vector2) -> void:
	camera.end_drag()


func _exit_tree() -> void:
	Engine.time_scale = 1.0
