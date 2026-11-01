class_name IslandDeployer
extends Node
## Kéo đảo vệ tinh mua thêm trong trận như kéo xà lan. Đảo mua đậu cạnh đảo chính (MapLayout.satellite_docks); người chơi
## chạm giữ đảo rồi kéo tới chỗ tuỳ ý trên biển (không theo ô có sẵn): đảo không dính theo ngón tay mà được lai dắt, tăng tốc
## từ từ, chạy tối đa island_tow_speed và phanh trước chỗ đến (EconomyData). Vòng lam dưới ngón tay báo chỗ đặt được (cam)
## hay không (đỏ). Thả ở chỗ hợp lệ và đủ vàng thì trừ phí kéo (Profile.island_move_cost) trong trận, đảo tiếp tục lai dắt
## tới nơi rồi mới mở bệ; thả chỗ không hợp lệ hay thiếu vàng thì đảo lai dắt về chỗ cũ, không tốn phí.
## Đảo có lô cốt thì không dời được. Đảo cấp sẵn của màn nằm cố định (mỗi màn sắp xếp riêng).

signal deployed(satellite_index: int)
signal arrived(satellite_index: int)
signal rejected
signal changed

## Kéo bắt được đảo trong chừng này pixel (ở độ phân giải gốc) quanh tâm đảo.
const PICK_RADIUS: float = 110.0
## Đảo coi là đã tới nơi khi cách đích chừng này đơn vị và gần như dừng.
const ARRIVE_DISTANCE: float = 0.05
const ARRIVE_SPEED: float = 0.3
## Bóng và bọt quanh đảo chỉ dựng lại nhiều nhất chừng này giây một lần khi đảo đang chạy.
const RELAYOUT_INTERVAL: float = 0.1

var battle: BattleController

var _free_count: int = 0
var _pier_count: int = 0
var _docks: PackedVector3Array = PackedVector3Array()
## Chỉ số đảo (trong island.satellites) → chỗ đã đặt (hoặc chỗ đậu); đảo trở về đây nếu bị từ chối.
var _home: Dictionary[int, Vector3] = {}
## Đảo đã kéo ra khỏi chỗ đậu (đã trả phí).
var _placed: Dictionary[int, bool] = {}
## Đích lai dắt hiện tại và vận tốc của từng đảo.
var _goal: Dictionary[int, Vector3] = {}
var _velocity: Dictionary[int, Vector3] = {}
var _dragging: int = -1
var _finger: Vector3 = Vector3.ZERO
var _finger_valid: bool = false
var _relayout_clock: float = 0.0
var _markers: MeshInstance3D
var _hint: Label


func setup(target: BattleController) -> void:
	battle = target
	_free_count = Profile.free_island_count()
	_docks = battle.layout.satellite_docks
	_pier_count = battle.island.pads.size() - battle.island.satellites.size()
	_home.clear()
	_placed.clear()
	_goal.clear()
	_velocity.clear()
	_dragging = -1
	for k: int in range(_free_count, battle.island.satellites.size()):
		_home[k] = _dock_of(k)
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
	return bought_count() - _placed.size()


func is_dragging() -> bool:
	return _dragging >= 0


func is_deployed(satellite: int) -> bool:
	return _placed.has(satellite)


## Chỗ đã đặt của đảo (hoặc chỗ đậu nếu chưa kéo ra).
func home_of(satellite: int) -> Vector3:
	return _home.get(satellite, battle.layout.satellite_centers[satellite])


## Đảo đang được lai dắt (chưa tới đích).
func is_towing(satellite: int = -1) -> bool:
	if satellite >= 0:
		return _goal.has(satellite)
	return not _goal.is_empty()


## Chỗ ngón tay chỉ có đặt được đảo đang kéo không.
func finger_valid() -> bool:
	return _finger_valid


## Đưa mọi đảo mua về chỗ đậu (khi chơi lại).
func reset() -> void:
	if battle == null:
		return
	for k: int in _home.keys():
		_place(k, _dock_of(k), true)
		_pad_of(k).locked = true
		_home[k] = _dock_of(k)
	_placed.clear()
	_goal.clear()
	_velocity.clear()
	_dragging = -1
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
	_pad_of(best).locked = true
	_finger = battle.layout.satellite_centers[best]
	_finger_valid = false
	_goal[best] = _finger
	_rebuild_markers()
	return true


## Ngón tay chỉ đích; đảo sẽ được lai dắt tới đó trong _process, không nhảy tới ngay.
func drag_to(screen_position: Vector2) -> void:
	if _dragging < 0:
		return
	var point: Vector3 = battle.camera.ground_point(screen_position)
	_finger = Vector3(point.x, 0.0, point.z)
	_finger_valid = battle.layout.island_spot_valid(_finger, _dragging)
	_goal[_dragging] = _finger
	_rebuild_markers()


## Thả đảo: chỗ hợp lệ và đủ vàng thì trả phí kéo, đảo lai dắt tới chỗ đó; không thì lai dắt về chỗ cũ.
func end_drag() -> void:
	if _dragging < 0:
		return
	var k: int = _dragging
	_dragging = -1
	if _finger_valid and battle.economy.spend(Profile.island_move_cost()):
		_home[k] = _finger
		_placed[k] = true
		_goal[k] = _finger
		deployed.emit(k)
		Events.ui_clicked.emit()
	else:
		_goal[k] = home_of(k)
		if _finger_valid:
			rejected.emit()
	_finger_valid = false
	_rebuild_markers()
	changed.emit()


## Huỷ kéo (chụm hai ngón): đảo lai dắt về chỗ cũ, không tốn phí.
func cancel() -> void:
	if _dragging < 0:
		return
	_goal[_dragging] = home_of(_dragging)
	_dragging = -1
	_finger_valid = false
	_rebuild_markers()


## Một bước lai dắt: tăng tốc dần về phía đích, phanh sao cho vừa dừng đúng đích.
func tow_step(delta: float) -> void:
	if battle == null or _goal.is_empty():
		return
	var speed: float = Profile.economy_rules.island_tow_speed
	var accel: float = Profile.economy_rules.island_tow_accel
	_relayout_clock += delta
	for k: int in _goal.keys():
		var here: Vector3 = battle.layout.satellite_centers[k]
		var step: Dictionary = tow_motion(here, _velocity.get(k, Vector3.ZERO), _goal[k], speed, accel, delta)
		_velocity[k] = step["velocity"]
		var arrived_now: bool = step["arrived"]
		_place(k, _goal[k] if arrived_now else step["position"], arrived_now and _dragging != k)
		if arrived_now:
			_finish_tow(k)
	if _relayout_clock >= RELAYOUT_INTERVAL:
		_relayout_clock = 0.0
		battle.island.relayout(battle.layout)
		battle.update_island_discs()


## Chuyển động lai dắt thuần: từ vị trí here, vận tốc velocity tới đích goal, trong delta giây. Trả
## {"position", "velocity", "arrived"}. Tốc độ mong muốn là min(tốc độ tối đa, sqrt(2·gia tốc·quãng còn lại)) nên đảo
## nhấc bước dần và phanh êm; vận tốc đổi tối đa accel·delta mỗi bước.
static func tow_motion(here: Vector3, velocity: Vector3, goal: Vector3, speed: float, accel: float, delta: float) -> Dictionary:
	var to_goal: Vector3 = goal - here
	to_goal.y = 0.0
	var distance: float = to_goal.length()
	if distance < ARRIVE_DISTANCE and velocity.length() < ARRIVE_SPEED:
		return {"position": goal, "velocity": Vector3.ZERO, "arrived": true}
	var wanted: Vector3 = Vector3.ZERO
	if distance > 0.0:
		wanted = to_goal / distance * minf(speed, sqrt(2.0 * accel * distance))
	var next_velocity: Vector3 = velocity.move_toward(wanted, accel * delta)
	var travel: Vector3 = next_velocity * delta
	if travel.length() >= distance:
		return {"position": goal, "velocity": Vector3.ZERO, "arrived": true}
	return {"position": here + travel, "velocity": next_velocity, "arrived": false}


func _finish_tow(k: int) -> void:
	_goal.erase(k)
	_velocity.erase(k)
	if _dragging == k:
		# Ngón tay còn giữ: đảo tới chỗ ngón tay chỉ nhưng vẫn đang kéo, giữ nguyên đích.
		_goal[k] = _finger
		return
	if _placed.has(k):
		_pad_of(k).locked = false
		arrived.emit(k)
	_rebuild_markers()


func _process(delta: float) -> void:
	tow_step(delta)
	if _hint != null and battle != null:
		_hint.visible = docked_count() > 0 and not battle.is_over()


func _dock_of(satellite: int) -> Vector3:
	return _docks[satellite - _free_count]


func _pad_of(satellite: int) -> TowerPad:
	return battle.island.pads[_pier_count + satellite]


## Đặt tâm đảo satellite tại center; đảo và bệ đi theo ngay, bóng và bọt dựng lại khi đảo dừng (hoặc theo nhịp trong tow_step).
func _place(satellite: int, center: Vector3, rebuild_now: bool = false) -> void:
	battle.layout.satellite_centers[satellite] = center
	battle.layout.pad_positions[_pier_count + satellite] = center
	if rebuild_now:
		battle.island.relayout(battle.layout)
		battle.update_island_discs()


func _rebuild_markers() -> void:
	var st: SurfaceTool = MeshKit.begin()
	var radius: float = battle.layout.satellite_radius
	if _dragging >= 0:
		var color: Color = UiStyle.RESCUE_ORANGE if _finger_valid else Color(0.9, 0.25, 0.2)
		MeshKit.ring(st, _finger, radius - 0.9, radius, 0.3, 0.55, 24, color, color)
	# Đảo còn đậu: viền cam quanh để biết kéo được.
	for k: int in range(_free_count, battle.island.satellites.size()):
		if not _placed.has(k) and k != _dragging and not _goal.has(k):
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
