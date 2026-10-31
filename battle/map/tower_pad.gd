class_name TowerPad
extends Node3D
## Bệ lô cốt: phao tròn nổi với viền cam. Trống và chọn được thì viền sáng nhấp nháy;
## đang chọn thì viền sáng hẳn. Vật liệu dùng chung giữa mọi bệ để Godot gộp lệnh vẽ.

## Bán kính phao, đơn vị Godot (bệ = 1 ô = 4 đơn vị, chừa khe giữa hai bệ).
const RADIUS: float = 1.7
const PONTOON_HEIGHT: float = 0.9
## Mặt trên của phao, cao hơn đỉnh sóng.
const TOP_HEIGHT: float = 0.7
const RING_COLOR: Color = Color(1.0, 0.45, 0.1)
const PONTOON_COLOR: Color = Color(0.74, 0.72, 0.66)
const GLOW_MIN: float = 0.3
const GLOW_MAX: float = 1.6
const GLOW_SPEED: float = 3.0

static var _pontoon_mesh: CylinderMesh
static var _ring_mesh: TorusMesh
static var _pontoon_material: StandardMaterial3D
static var _ring_idle: StandardMaterial3D
static var _ring_selectable: StandardMaterial3D
static var _ring_selected: StandardMaterial3D

var pad_index: int = -1
var occupied: bool = false:
	set(value):
		occupied = value
		_refresh()
var selected: bool = false:
	set(value):
		selected = value
		_refresh()

var _ring: MeshInstance3D


func _init() -> void:
	_ensure_shared_resources()
	var pontoon: MeshInstance3D = MeshInstance3D.new()
	pontoon.name = "Pontoon"
	pontoon.mesh = _pontoon_mesh
	pontoon.material_override = _pontoon_material
	pontoon.position.y = TOP_HEIGHT - PONTOON_HEIGHT * 0.5
	pontoon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pontoon)
	_ring = MeshInstance3D.new()
	_ring.name = "Ring"
	_ring.mesh = _ring_mesh
	_ring.position.y = TOP_HEIGHT + 0.02
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	_refresh()


## Bệ trống thì chọn được để xây.
func is_selectable() -> bool:
	return not occupied


## Cập nhật độ sáng nhấp nháy của mọi bệ chọn được. Gọi một lần mỗi khung từ trận.
static func animate_glow(time_seconds: float) -> void:
	_ensure_shared_resources()
	var t: float = 0.5 + 0.5 * sin(time_seconds * GLOW_SPEED)
	_ring_selectable.emission_energy_multiplier = lerpf(GLOW_MIN, GLOW_MAX, t)


func _refresh() -> void:
	if _ring == null:
		return
	if selected:
		_ring.material_override = _ring_selected
	elif is_selectable():
		_ring.material_override = _ring_selectable
	else:
		_ring.material_override = _ring_idle


static func _ensure_shared_resources() -> void:
	if _pontoon_mesh != null:
		return
	_pontoon_mesh = CylinderMesh.new()
	_pontoon_mesh.top_radius = RADIUS
	_pontoon_mesh.bottom_radius = RADIUS * 0.92
	_pontoon_mesh.height = PONTOON_HEIGHT
	_pontoon_mesh.radial_segments = 24
	_pontoon_mesh.rings = 1
	_ring_mesh = TorusMesh.new()
	_ring_mesh.inner_radius = RADIUS - 0.3
	_ring_mesh.outer_radius = RADIUS + 0.05
	_ring_mesh.rings = 24
	_ring_mesh.ring_segments = 6
	_pontoon_material = StandardMaterial3D.new()
	_pontoon_material.albedo_color = PONTOON_COLOR
	_pontoon_material.roughness = 0.8
	_ring_idle = _make_ring_material(0.0)
	_ring_selectable = _make_ring_material(GLOW_MIN)
	_ring_selected = _make_ring_material(2.5)
	_ring_selected.albedo_color = Color(1.0, 0.85, 0.4)
	_ring_selected.emission = Color(1.0, 0.8, 0.3)


static func _make_ring_material(energy: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = RING_COLOR
	material.roughness = 0.5
	material.emission_enabled = energy > 0.0
	material.emission = RING_COLOR
	material.emission_energy_multiplier = energy
	return material
