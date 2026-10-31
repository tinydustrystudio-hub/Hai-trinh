class_name Tower
extends Node3D
## Lô cốt chung: đọc TowerData, giữ cấp hiện tại, tìm mục tiêu 5 lần mỗi giây, xoay đầu nòng về mục tiêu.
## Cách bắn do lớp con quyết định (fire()). Không có _process riêng: BattleController gọi tick() mỗi nhịp trận.

var data: TowerData
var level: int = 1
var pad: TowerPad
## Tổng Thép đã bỏ vào lô cốt (xây và nâng), để tính hoàn lại khi bán.
var invested: int = 0
var target: Enemy = null

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
	invested = tower_data.level(1).steel_cost
	_build_visual()
	_setup_effects(effects)


func stats() -> TowerLevel:
	return data.level(level)


func range_units() -> float:
	return stats().range_units()


## Một nhịp trận: tìm lại mục tiêu theo nhịp, xoay nòng, rồi để lớp con bắn.
func tick(delta: float) -> void:
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
