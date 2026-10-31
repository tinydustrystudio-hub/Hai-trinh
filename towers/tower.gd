class_name Tower
extends Node3D
## Lô cốt chung: đọc TowerData, giữ cấp hiện tại (1–4, rồi nhánh 5A hoặc 5B), tìm mục tiêu 5 lần mỗi giây,
## xoay đầu nòng về mục tiêu.
## Cách bắn do lớp con quyết định (fire()). Không có _process riêng: BattleController gọi tick() mỗi nhịp trận.

## Đầu nòng phình to chừng này khi đang MEGA.
const MEGA_TURRET_SCALE: float = 1.35

var data: TowerData
var level: int = 1
## Nhánh cấp 5 đã chọn, hoặc null.
var branch: TowerBranch = null
var pad: TowerPad
## Tổng Thép đã bỏ vào lô cốt (xây và nâng), để tính hoàn lại khi bán.
var invested: int = 0
var target: Enemy = null
## Thanh Quá tải; giữ nguyên khi nâng cấp.
var overload: Overload

var _pool: EnemyPool
var _retarget_left: float = 0.0
var _turret: Node3D


## Đặt lô cốt lên bệ. Gọi trước khi vào cây. effects là nút chứa các bộ vẽ hiệu ứng dùng chung
## (BulletRenderer, GluePuddles); để null khi thử logic.
func setup(tower_data: TowerData, on_pad: TowerPad, pool: EnemyPool, effects: Node) -> void:
	data = tower_data
	pad = on_pad
	_pool = pool
	level = 1
	branch = null
	invested = tower_data.level(1).steel_cost
	overload = Overload.new(tower_data)
	overload.ready.connect(func() -> void: Events.overload_ready.emit(self))
	overload.mega_started.connect(_on_mega_started)
	overload.mega_ended.connect(_on_mega_ended)
	_build_visual()
	_setup_effects(effects)


## Số liệu đang dùng: của nhánh nếu đã chọn, không thì của cấp hiện tại.
func stats() -> TowerLevel:
	return branch if branch != null else data.level(level)


## Còn nâng được cấp thường (1–4) không.
func can_level_up() -> bool:
	return branch == null and level < data.max_level()


## Đã tới cấp 4: lần nâng kế tiếp là chọn nhánh.
func needs_branch() -> bool:
	return branch == null and level >= data.max_level() and not data.branches.is_empty()


func is_max_level() -> bool:
	return branch != null or (level >= data.max_level() and data.branches.is_empty())


## Giá lần nâng kế tiếp (cấp thường), hoặc -1.
func next_level_cost() -> int:
	return data.level(level + 1).steel_cost if can_level_up() else -1


## Lên một cấp thường; Thép do BattleController trừ trước.
func level_up() -> void:
	if not can_level_up():
		return
	level += 1
	invested += data.level(level).steel_cost
	_on_stats_changed()


## Chọn nhánh cấp 5; lanes để Hồ Keo tìm chỗ đặt hồ trên luồng.
func choose_branch(chosen: TowerBranch, lanes: Array[Lane]) -> void:
	if not needs_branch() or not data.branches.has(chosen):
		return
	branch = chosen
	level = data.max_level() + 1
	invested += chosen.steel_cost
	_on_branch_chosen(lanes)
	_on_stats_changed()


## Lớp con ghi đè: số liệu vừa đổi (nâng cấp).
func _on_stats_changed() -> void:
	pass


## Lớp con ghi đè: vừa chọn nhánh.
func _on_branch_chosen(_lanes: Array[Lane]) -> void:
	pass


func range_units() -> float:
	return stats().range_units()


## Kích MEGA nếu thanh đã đầy; trả true nếu đã kích.
func activate_mega() -> bool:
	return overload.activate()


## Hệ số Quá tải hiện tại: ×3 (hỗ trợ ×1,5) khi MEGA, 0,2 khi làm mát, 1 lúc bình thường.
func overload_multiplier() -> float:
	return overload.multiplier()


func _on_mega_started() -> void:
	# Hình thái MEGA tạm: đầu nòng phình to; model thật ở tháng sau.
	if _turret != null:
		_turret.scale = Vector3.ONE * MEGA_TURRET_SCALE
	Events.mega_started.emit(self)


func _on_mega_ended() -> void:
	if _turret != null:
		_turret.scale = Vector3.ONE
	Events.mega_ended.emit(self)


## Một nhịp trận: tìm lại mục tiêu theo nhịp, xoay nòng, rồi để lớp con bắn.
func tick(delta: float) -> void:
	overload.advance(delta)
	_retarget_left -= delta
	var origin: Vector3 = global_position
	var range_squared: float = range_units() * range_units()
	if _retarget_left <= 0.0 or not Targeting.can_hit(target, origin, range_squared, data.target_layers):
		_retarget_left = Targeting.RETARGET_INTERVAL
		target = Targeting.pick(_pool.active, origin, range_units(), data.target_layers)
	if target != null and _turret != null:
		var to_target: Vector3 = target.global_position - _turret.global_position
		to_target.y = 0.0
		if to_target.length() > 0.01:
			_turret.global_basis = Basis.looking_at(to_target, Vector3.UP)
	fire(delta)


## Lớp con ghi đè: bắn trong delta giây.
func fire(_delta: float) -> void:
	pass


## Lớp con ghi đè: chuẩn bị hiệu ứng (vệt đạn, vũng keo…).
func _setup_effects(_effects: Node) -> void:
	pass


## Đầu nòng (vị trí thế giới) để vẽ vệt đạn.
func muzzle_position() -> Vector3:
	if _turret == null:
		return global_position + Vector3.UP
	return _turret.global_position + (-_turret.global_basis.z) * TowerMeshes.BARREL_LENGTH + Vector3(0.0, 0.1, 0.0)


func _build_visual() -> void:
	var body: MeshInstance3D = MeshInstance3D.new()
	body.name = "Body"
	body.mesh = TowerMeshes.base_mesh(data)
	body.material_override = TowerMeshes.material()
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(body)
	_turret = Node3D.new()
	_turret.name = "Turret"
	_turret.position = Vector3(0.0, TowerMeshes.TURRET_Y, 0.0)
	add_child(_turret)
	var head: MeshInstance3D = MeshInstance3D.new()
	head.name = "Head"
	head.mesh = TowerMeshes.turret_mesh(data)
	head.material_override = TowerMeshes.material()
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_turret.add_child(head)
