class_name IslandDeployer
extends Node
## Kéo đảo vệ tinh mua thêm ra ô đặt trong trận. Đảo mua đậu cạnh đảo chính (MapLayout.satellite_docks); người chơi kéo nó
## tới một ô lam trống, thả thì đảo nằm đó và mở bệ để xây lô cốt. Mỗi lần kéo ra (hay dời lại) tốn phí kéo (Profile.island_move_cost)
## trừ vào Tiền Vàng trong trận; thiếu vàng hoặc thả ra ngoài ô thì đảo về chỗ cũ. Đảo có lô cốt thì không dời được.
## Đảo cấp sẵn của màn nằm cố định ở ô mặc định.

signal deployed(satellite_index: int, slot: int)
signal rejected
signal changed

## Kéo bắt được đảo trong chừng này pixel (ở độ phân giải gốc) quanh tâm đảo.
const PICK_RADIUS: float = 110.0
## Thả gần ô trong chừng này đơn vị thì ô đó hút đảo vào.
const SNAP_UNITS: float = 14.0

var battle: BattleController

var _free_count: int = 0
var _pier_count: int = 0
var _docks: PackedVector3Array = PackedVector3Array()
## Chỉ số đảo (trong island.satellites) → ô đã kéo ra.
var _slot_of: Dictionary[int, int] = {}
var _dragging: int = -1
var _origin: Vector3 = Vector3.ZERO
var _hover_slot: int = -1
var _markers: MeshInstance3D
var _hint: Label


func setup(target: BattleController) -> void:
	battle = target
	_free_count = Profile.free_island_count()
	_docks = battle.layout.satellite_docks
	_pier_count = battle.island.pads.size() - battle.island.satellites.size()
	_slot_of.clear()
	_dragging = -1
	_hover_slot = -1
	for k: int in battle.island.satellites.size():
		if k >= _free_count:
			_pad_of(k).locked = true
	if _markers == null:
		_markers = MeshInstance3D.new()
		_markers.name = "IslandMarkers"
		_markers.material_override = Island.solid_material()
		battle.island.add_child(_markers)
		_build_hint()
	_rebuild_markers()


## Số đảo mua thêm của trận này.
func bought_count() -> int:
	return maxi(battle.island.satellites.size() - _free_count, 0)


## Số đảo mua thêm còn đậu cạnh đảo chính.
func docked_count() -> int:
	return bought_count() - _slot_of.size()


func is_dragging() -> bool:
	return _dragging >= 0


func is_deployed(satellite: int) -> bool:
	return _slot_of.has(satellite)


func slot_of(satellite: int) -> int:
	return _slot_of.get(satellite, -1)


## Ô trống: không phải ô mặc định của đảo cấp sẵn và chưa có đảo kéo ra.
func slot_is_free(slot: int) -> bool:
	return slot >= _free_count and slot < battle.layout.slot_count() and not _slot_of.values().has(slot)


func slot_position(slot: int) -> Vector3:
	return battle.layout.satellite_slots[slot]


## Đưa mọi đảo mua về chỗ đậu (khi chơi lại).
func reset() -> void:
	if battle == null:
		return
	for k: int in _slot_of.keys():
		_place(k, _dock_of(k))
		_pad_of(k).locked = true
	_slot_of.clear()
	_dragging = -1
	_hover_slot = -1
	_rebuild_markers()
	changed.emit()


## Bắt đầu kéo nếu điểm chạm trúng một đảo mua thêm; trả true nếu bắt được.
func begin_drag(screen_position: Vector2) -> bool:
	var best: int = -1
	var best_distance: float = PICK_RADIUS
	for k: int in range(_free_count, battle.island.satellites.size()):
		if _pad_of(k).occupied:
			continue
		var d: float = battle.camera.unproject_position(battle.layout.satellite_centers[k]).distance_to(screen_position)
		if d < best_distance:
			best_distance = d
			best = k
	if best < 0:
		return false
	_dragging = best
	_origin = battle.layout.satellite_centers[best]
	_hover_slot = -1
	_rebuild_markers()
	return true


## Đảo đi theo ngón tay, hút vào ô trống gần nhất.
func drag_to(screen_position: Vector2) -> void:
	if _dragging < 0:
		return
	var point: Vector3 = battle.camera.ground_point(screen_position)
	_hover_slot = nearest_free_slot(point)
	_place(_dragging, slot_position(_hover_slot) if _hover_slot >= 0 else Vector3(point.x, 0.0, point.z))


## Thả đảo: vào ô trống thì trả phí kéo và đặt; không thì về chỗ cũ.
func end_drag() -> void:
	if _dragging < 0:
		return
	var k: int = _dragging
	_dragging = -1
	if _hover_slot >= 0 and battle.economy.spend(Profile.island_move_cost()):
		_place(k, slot_position(_hover_slot))
		_slot_of[k] = _hover_slot
		_pad_of(k).locked = false
		deployed.emit(k, _hover_slot)
		Events.ui_clicked.emit()
	else:
		_place(k, _origin)
		if _hover_slot >= 0:
			rejected.emit()
	_hover_slot = -1
	_rebuild_markers()
	changed.emit()


## Huỷ kéo (chụm hai ngón): đảo về chỗ cũ, không tốn phí.
func cancel() -> void:
	if _dragging < 0:
		return
	_place(_dragging, _origin)
	_dragging = -1
	_hover_slot = -1
	_rebuild_markers()


## Ô trống gần điểm point nhất trong SNAP_UNITS, −1 nếu không có.
func nearest_free_slot(point: Vector3) -> int:
	var best: int = -1
	var best_distance: float = SNAP_UNITS
	for slot: int in battle.layout.slot_count():
		if not slot_is_free(slot):
			continue
		var d: float = Vector2(point.x - slot_position(slot).x, point.z - slot_position(slot).z).length()
		if d < best_distance:
			best_distance = d
			best = slot
	return best


func _process(_delta: float) -> void:
	if _hint != null and battle != null:
		_hint.visible = docked_count() > 0 and not battle.is_over()


func _dock_of(satellite: int) -> Vector3:
	return _docks[satellite - _free_count]


func _pad_of(satellite: int) -> TowerPad:
	return battle.island.pads[_pier_count + satellite]


## Đặt tâm đảo satellite tại center; đảo, bệ, bóng và bọt đi theo.
func _place(satellite: int, center: Vector3) -> void:
	battle.layout.satellite_centers[satellite] = center
	battle.layout.pad_positions[_pier_count + satellite] = center
	battle.island.relayout(battle.layout)
	battle.update_island_discs()


func _rebuild_markers() -> void:
	var st: SurfaceTool = MeshKit.begin()
	var radius: float = battle.layout.satellite_radius
	if _dragging >= 0:
		for slot: int in battle.layout.slot_count():
			if slot_is_free(slot):
				var hovered: bool = slot == _hover_slot
				var color: Color = UiStyle.RESCUE_ORANGE if hovered else AllianceFortress.GLASS.lightened(0.3)
				MeshKit.ring(st, slot_position(slot), radius - 0.9, radius, 0.3, 0.55, 24, color, color)
	# Đảo còn đậu: viền cam quanh để biết kéo được.
	for k: int in range(_free_count, battle.island.satellites.size()):
		if not _slot_of.has(k) and k != _dragging:
			var center: Vector3 = battle.layout.satellite_centers[k]
			MeshKit.ring(st, center, radius + 0.5, radius + 1.2, 0.3, 0.55, 24, UiStyle.RESCUE_ORANGE, UiStyle.RESCUE_ORANGE)
	_markers.mesh = MeshKit.commit(st)
	if _hint != null:
		_hint.visible = docked_count() > 0 and not battle.is_over()
		_hint.text = tr(&"ISLAND_DEPLOY_HINT") % Profile.island_move_cost()


func _build_hint() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "HintLayer"
	add_child(layer)
	_hint = UiStyle.label(UiStyle.TEXT_SIZE - 6)
	_hint.name = "Hint"
	_hint.add_theme_color_override(&"font_color", UiStyle.RESCUE_ORANGE.lightened(0.3))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 48)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_hint)
