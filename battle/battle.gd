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
## Trận chậm còn chừng này trong lúc chọn nhánh cấp 5 (GDD mục 7.10).
const BRANCH_CHOICE_SPEED: float = 0.3
const LAYER_KEYS: Dictionary[EnemyData.Layer, StringName] = {
	EnemyData.Layer.SURFACE: &"LAYER_SURFACE",
	EnemyData.Layer.UNDERWATER: &"LAYER_UNDERWATER",
	EnemyData.Layer.AIR: &"LAYER_AIR",
}
## Lớp script của từng loại lô cốt theo id trong TowerData.
const TOWER_SCRIPTS: Dictionary[StringName, GDScript] = {
	&"machine_gun": preload("res://towers/machine_gun.gd"),
	&"glue_sprayer": preload("res://towers/glue_sprayer.gd"),
	&"light_beam": preload("res://towers/light_beam.gd"),
}
## Trần số địch cùng lúc (GDD mục 1.3, CLAUDE.md).
const MAX_ACTIVE_ENEMIES: int = 60
## Ở cảnh thử, địch mới xuất hiện rải trong đoạn đầu luồng này (tỉ lệ chiều dài luồng).
const STRESS_SPREAD: float = 0.85

@export var layout: MapLayout = preload("res://data/maps/north_dock_layout.tres")
@export var wave_data: WaveData = preload("res://data/waves/north_dock_waves.tres")
## Các lô cốt chọn được trong vòng chọn, theo thứ tự hiện trên vòng.
@export var tower_choices: Array[TowerData] = [
	preload("res://data/towers/machine_gun.tres"),
	preload("res://data/towers/glue_sprayer.tres"),
	preload("res://data/towers/light_beam.tres"),
]

var state: State = State.PREPARING
var lanes: Array[Lane] = []
var selected_pad: TowerPad = null
var paused: bool = false
var speed: float = 1.0
## Đang mở hai thẻ chọn nhánh cấp 5.
var choosing_branch: bool = false
## Cảnh thử hiệu năng: không có đợt, luôn giữ đủ MAX_ACTIVE_ENEMIES địch, đảo không chìm.
var stress_mode: bool = false
## Mili giây từ lúc chạy game tới lúc trận sẵn sàng (kế hoạch mục 7: không quá 3 giây).
var ready_msec: int = 0

var towers: Array[Tower] = []

var _enemy_types: Array[EnemyData] = []
## Các loại địch đã xuất hiện trong trận (cho thẻ địch ở màn Tạm dừng).
var _enemies_met: Array[EnemyData] = []
## Đợt gần nhất đã cho luồng hiện rõ, để chỉ hiện một lần mỗi đợt.

@onready var ocean: Ocean = $Ocean
@onready var island: Island = $Island
@onready var lanes_root: Node3D = $Lanes
@onready var camera: BattleCamera = $BattleCamera
@onready var touch_input: TouchInput = $Systems/TouchInput
@onready var spawner: WaveSpawner = $Systems/WaveSpawner
@onready var buoyancy: Buoyancy = $Systems/Buoyancy
@onready var enemy_pool: EnemyPool = $EnemyPool
@onready var economy: Economy = $Systems/Economy
@onready var effects: Node3D = $Effects
@onready var bullets: BulletRenderer = $Effects/BulletRenderer
@onready var glue_puddles: GluePuddles = $Effects/GluePuddles
@onready var beams: BeamRenderer = $Effects/Beams
@onready var overload_bars: OverloadBars = $Effects/OverloadBars
@onready var mega_bursts: MegaBursts = $Effects/MegaBursts
@onready var mega_beacons: MegaBeacons = $Effects/MegaBeacons
@onready var sound_board: SoundBoard = $Effects/SoundBoard
@onready var haptics: Haptics = $Effects/Haptics
@onready var music: MusicPlayer = $Effects/Music
@onready var hud: Hud = $HUD
@onready var sun: DirectionalLight3D = $Sun
var weather: Weather
@onready var world_environment: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	build_map()
	_build_weather()
	enemy_pool.ocean = ocean
	enemy_pool.face_camera(camera.global_basis)
	overload_bars.face_camera(camera.global_basis)
	touch_input.tapped.connect(_on_tapped)
	touch_input.drag_started.connect(camera.begin_drag)
	touch_input.drag_moved.connect(camera.drag_to)
	touch_input.drag_ended.connect(_on_drag_ended)
	touch_input.pinch_started.connect(camera.cancel_drag)
	touch_input.pinch_started.connect(close_build_ring)
	touch_input.drag_started.connect(close_build_ring.unbind(1))
	touch_input.zoomed.connect(camera.zoom_by)
	touch_input.zoomed.connect(close_build_ring.unbind(2))
	economy.changed.connect(_on_steel_changed)
	hud.build_ring.tower_chosen.connect(_on_tower_chosen)
	hud.build_ring.option_previewed.connect(_on_option_previewed)
	hud.build_ring.cancelled.connect(close_build_ring)
	hud.upgrade_ring.upgrade_requested.connect(_on_upgrade_requested)
	hud.upgrade_ring.branch_requested.connect(_on_branch_requested)
	hud.upgrade_ring.sell_requested.connect(_on_sell_requested)
	hud.branch_cards.branch_chosen.connect(_on_branch_chosen)
	hud.branch_cards.cancelled.connect(close_branch_cards)
	hud.mega_tray.mega_requested.connect(activate_mega)
	Events.overload_ready.connect(_on_overload_ready)
	Events.mega_started.connect(_on_mega_started)
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
	hud.pause_requested.connect(pause)
	hud.resume_requested.connect(resume)
	hud.speed_toggled.connect(toggle_fast)
	hud.call_wave_requested.connect(call_wave_early)
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
	weather.advance(delta, enemy_pool.wave_time())
	spawner.advance(delta)
	_update_lane_warnings()
	if is_over():
		return
	enemy_pool.advance(delta)
	glue_puddles.begin()
	beams.begin()
	for tower: Tower in towers:
		tower.tick(delta)
		if tower is GlueSprayer:
			(tower as GlueSprayer).draw_puddles(glue_puddles)
		elif tower is LightBeam:
			(tower as LightBeam).draw_beam(beams)
	glue_puddles.finish()
	beams.finish()
	bullets.advance(delta)
	overload_bars.update_bars(towers, delta)
	mega_bursts.advance(delta)
	mega_beacons.update_beacons(towers)
	if stress_mode:
		spawn_burst(MAX_ACTIVE_ENEMIES - enemy_pool.active_count())
	island.set_tilt(buoyancy.tilt_degrees())
	island.bob(ocean, enemy_pool.wave_time())


func start_battle() -> void:
	stress_mode = false
	enemy_pool.clear()
	_clear_towers()
	close_build_ring()
	close_branch_cards()
	hud.mega_tray.clear()
	buoyancy.reset(layout.starting_buoyancy)
	economy.reset(layout.starting_steel)
	state = State.PREPARING
	_enemies_met.clear()
	hud.hide_pause()
	set_paused(false)
	set_speed(1.0)
	hud.hide_result()
	spawner.start(wave_data)
	_update_lane_warnings()


## Chuyển sang cảnh thử hiệu năng.
func enter_stress_mode() -> void:
	stress_mode = true
	spawner.stop()
	_update_lane_warnings()
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


## Xây lô cốt lên bệ nếu bệ trống và đủ Thép; trả lô cốt mới hoặc null.
func build_tower(pad: TowerPad, data: TowerData) -> Tower:
	if pad == null or pad.occupied or is_over():
		return null
	if not economy.spend(data.level(1).steel_cost):
		return null
	var tower: Tower = TOWER_SCRIPTS.get(data.id, Tower).new()
	tower.name = "Tower%d" % pad.pad_index
	tower.setup(data, pad, enemy_pool, effects)
	# Lô cốt là con của bệ: lô cốt trên mỏm bến nghiêng theo pháo đài khi mất Độ Nổi.
	pad.add_child(tower)
	pad.occupied = true
	towers.append(tower)
	Events.tower_built.emit(tower)
	return tower


## Đóng vòng chọn, vòng nâng cấp và bỏ chọn bệ.
func close_build_ring() -> void:
	if selected_pad != null:
		selected_pad.hide_range()
	hud.build_ring.close()
	hud.upgrade_ring.close()
	select_pad(null)


## Lô cốt đang đứng trên bệ, hoặc null.
func tower_on(pad: TowerPad) -> Tower:
	for tower: Tower in towers:
		if tower.pad == pad:
			return tower
	return null


## Nâng lô cốt lên một cấp thường nếu đủ Thép; trả true nếu đã nâng.
func upgrade_tower(tower: Tower) -> bool:
	if tower == null or not tower.can_level_up() or is_over():
		return false
	if not economy.spend(tower.next_level_cost()):
		return false
	tower.level_up()
	Events.tower_upgraded.emit(tower)
	return true


## Chọn nhánh cấp 5 cho lô cốt nếu đủ Thép; trả true nếu đã chọn.
func choose_branch(tower: Tower, chosen: TowerBranch) -> bool:
	if tower == null or not tower.needs_branch() or is_over():
		return false
	if not economy.spend(chosen.steel_cost):
		return false
	tower.choose_branch(chosen, lanes)
	Events.tower_upgraded.emit(tower)
	return true


## Bán lô cốt: hoàn 70% tổng Thép đã bỏ vào, trả bệ trống. Trả số Thép hoàn lại.
func sell_tower(tower: Tower) -> int:
	if tower == null or not towers.has(tower):
		return 0
	var refund: int = economy.refund_for(tower.invested)
	economy.earn(refund)
	towers.erase(tower)
	tower.pad.occupied = false
	hud.mega_tray.remove(tower)
	Events.tower_sold.emit(tower)
	tower.queue_free()
	return refund


## Kích MEGA cho lô cốt đã đầy thanh Quá tải; trả true nếu đã kích.
func activate_mega(tower: Tower) -> bool:
	if tower == null or not towers.has(tower) or is_over():
		return false
	return tower.activate_mega()


func open_branch_cards(tower: Tower) -> void:
	hud.upgrade_ring.close()
	hud.branch_cards.open(tower, economy.steel)
	choosing_branch = true
	_apply_time_scale()


func close_branch_cards() -> void:
	hud.branch_cards.close()
	choosing_branch = false
	_apply_time_scale()
	select_pad(null)


func _clear_towers() -> void:
	for tower: Tower in towers:
		tower.pad.occupied = false
		tower.queue_free()
	towers.clear()


func is_over() -> bool:
	return state == State.WON or state == State.LOST


func set_paused(value: bool) -> void:
	paused = value
	_apply_time_scale()


func set_speed(value: float) -> void:
	speed = value
	_apply_time_scale()
	hud.set_speed_label(speed)


## Tạm dừng trận và mở màn Tạm dừng (GDD mục 7.11).
func pause() -> void:
	if is_over() or paused:
		return
	close_build_ring()
	set_paused(true)
	hud.show_pause(tr(&"OBJECTIVE_HOLD") % wave_data.wave_count(), enemy_tips(), speed)


func resume() -> void:
	hud.hide_pause()
	set_paused(false)


func toggle_pause() -> void:
	if paused:
		resume()
	else:
		pause()


## Gọi đợt kế ngay khi đang chờ (nút Gọi đợt sớm).
func call_wave_early() -> void:
	if not is_over() and not stress_mode:
		spawner.call_next_wave_now()


## Tên các tầng địch có trong đợt index, đã dịch, không trùng.
func layer_names_in_wave(index: int) -> PackedStringArray:
	var names: PackedStringArray = PackedStringArray()
	if wave_data == null or index < 0 or index >= wave_data.wave_count():
		return names
	for group: SpawnGroup in wave_data.waves[index].groups:
		if group.enemy == null:
			continue
		var layer_name: String = tr(LAYER_KEYS[group.enemy.layer])
		if not names.has(layer_name):
			names.append(layer_name)
	return names


## Thẻ ngắn cho từng loại địch đã gặp (tên, điểm yếu), đã dịch.
func enemy_tips() -> PackedStringArray:
	var tips: PackedStringArray = PackedStringArray()
	for data: EnemyData in _enemies_met:
		tips.append(tr(StringName("%s_TIP" % data.name_key)))
	return tips


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


## Dựng thời tiết: màn mưa, sét và bộ điều khiển; kiểu ban đầu lấy từ ?weather=rain|storm (hoặc --weather=…), mặc định bình thường.
func _build_weather() -> void:
	var rain_fx: RainOverlay = RainOverlay.new()
	rain_fx.name = "RainOverlay"
	add_child(rain_fx)
	var lightning_fx: LightningOverlay = LightningOverlay.new()
	lightning_fx.name = "LightningOverlay"
	add_child(lightning_fx)
	weather = Weather.new()
	weather.name = "Weather"
	add_child(weather)
	weather.attach(ocean, sun, rain_fx, lightning_fx)
	var wanted: StringName = StringName(Settings.launch_value("weather"))
	weather.set_weather(Weather.by_id(wanted), true)


## Đổi thời tiết (bảng debug, thử): bình thường, mưa, bão.
func set_weather(id: StringName) -> void:
	weather.set_weather(Weather.by_id(id))


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
	_update_lane_warnings()
	close_build_ring()
	close_branch_cards()
	set_paused(false)
	set_speed(1.0)
	Events.battle_ended.emit(won)
	hud.show_result(won)


func _apply_time_scale() -> void:
	if paused:
		Engine.time_scale = 0.0
	else:
		Engine.time_scale = speed * (BRANCH_CHOICE_SPEED if choosing_branch else 1.0)


func _on_spawn_requested(enemy: EnemyData, lane_index: int) -> void:
	var spawned: Enemy = enemy_pool.acquire(enemy, lanes[lane_index])
	if not _enemies_met.has(enemy):
		_enemies_met.append(enemy)
	if spawned == null:
		spawner.notify_enemy_removed()
	else:
		spawned.counts_for_wave = true


func _on_wave_started(index: int, total: int) -> void:
	state = State.FIGHTING
	economy.on_wave_started()
	Events.wave_started.emit(index, total)


func _on_wave_cleared(index: int) -> void:
	state = State.RESTING
	Events.wave_cleared.emit(index)


func _on_wave_incoming(index: int, lane_indices: PackedInt32Array, seconds: float) -> void:
	Events.wave_incoming.emit(index, lane_indices, seconds)


## Luồng nào sắp có địch trong Lane.WARNING_SECONDS giây thì hiện luồng và bật đèn báo hướng trên đảo;
## địch đầu tiên của luồng đã ra thì tắt.
func _update_lane_warnings() -> void:
	for lane: Lane in lanes:
		var seconds: float = spawner.seconds_until_lane(lane.lane_index)
		var warning: bool = seconds >= 0.0 and seconds <= Lane.WARNING_SECONDS
		lane.set_warning(warning)
		island.set_lane_warning(lane.lane_index, warning)


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


func _on_enemy_killed(enemy: Enemy, reward: int) -> void:
	economy.earn(reward)
	if enemy.counts_for_wave:
		spawner.notify_enemy_removed()


func _on_tapped(screen_position: Vector2) -> void:
	var point: Vector3 = camera.ground_point(screen_position, TowerPad.TOP_HEIGHT)
	var pad: TowerPad = island.pad_near(point, TowerPad.RADIUS * PAD_PICK_TOLERANCE)
	var same: bool = pad == selected_pad
	close_build_ring()
	if pad == null or same or is_over():
		return
	select_pad(pad)
	var at: Vector2 = camera.unproject_position(pad.global_position)
	if pad.occupied:
		var tower: Tower = tower_on(pad)
		# Chạm thẳng vào lô cốt đã đầy thanh thì kích MEGA (GDD mục 3.1), không mở vòng nâng cấp.
		if tower != null and tower.overload.is_ready():
			select_pad(null)
			activate_mega(tower)
			return
		_open_upgrade_ring(tower, at)
	else:
		hud.build_ring.open(at, tower_choices, economy.steel)


func _open_upgrade_ring(tower: Tower, at: Vector2) -> void:
	if tower != null:
		tower.pad.show_range(tower.range_units())
		hud.upgrade_ring.open(at, tower, economy.steel, economy.refund_for(tower.invested))


func _on_upgrade_requested() -> void:
	var tower: Tower = hud.upgrade_ring.tower
	if upgrade_tower(tower):
		# Mở lại để hiện giá kế tiếp: nâng liền nhiều cấp không phải chạm lại bệ.
		_open_upgrade_ring(tower, camera.unproject_position(tower.pad.global_position))


func _on_branch_requested() -> void:
	open_branch_cards(hud.upgrade_ring.tower)


func _on_branch_chosen(chosen: TowerBranch) -> void:
	var tower: Tower = hud.branch_cards.tower
	choose_branch(tower, chosen)
	close_branch_cards()


func _on_sell_requested() -> void:
	var tower: Tower = hud.upgrade_ring.tower
	close_build_ring()
	sell_tower(tower)


## Xem trước một lô cốt trong vòng chọn: hiện tầm bắn cấp 1 trên bệ đang chọn.
func _on_option_previewed(data: TowerData) -> void:
	if selected_pad != null:
		selected_pad.show_range(data.level(1).range_units())


func _on_tower_chosen(data: TowerData) -> void:
	var pad: TowerPad = selected_pad
	close_build_ring()
	build_tower(pad, data)


func _on_overload_ready(tower: Node3D) -> void:
	if towers.has(tower):
		hud.mega_tray.add(tower as Tower)


func _on_mega_started(tower: Node3D) -> void:
	var fired: Tower = tower as Tower
	if fired == null or not towers.has(fired):
		return
	hud.mega_tray.remove(fired)
	mega_bursts.spawn(fired.global_position, fired.range_units())


func _on_steel_changed(value: int) -> void:
	Events.steel_changed.emit(value)


func _on_drag_ended(_screen_position: Vector2) -> void:
	camera.end_drag()


func _unhandled_input(event: InputEvent) -> void:
	# Esc trên web, nút Quay lại trên Android: tạm dừng hoặc tiếp tục (GDD mục 7.1).
	if event.is_action_pressed(&"ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			toggle_pause()
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			if is_node_ready() and DisplayServer.get_name() != "headless":
				on_focus_lost()


## Tự tạm dừng khi chuyển ứng dụng hoặc chuyển tab (GDD mục 7.11).
func on_focus_lost() -> void:
	pause()


func _exit_tree() -> void:
	Engine.time_scale = 1.0
