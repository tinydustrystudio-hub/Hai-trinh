class_name IslandDeployer
extends Node
## Kéo đảo vệ tinh mua thêm trong trận như kéo xà lan. Đảo mua đậu cạnh đảo chính (MapLayout.satellite_docks); người chơi
## chạm giữ đảo rồi kéo tới chỗ tuỳ ý trên biển (không theo ô có sẵn). Khi kéo hiện lưới trên mặt biển: ô xanh là chỗ đảo
## tới được, ô đỏ là chỗ không được (đè luồng, đảo chính, đảo khác hay ra ngoài vùng biển). Đảo không dính theo ngón tay mà
## được lai dắt: tăng tốc từ từ, chạy tối đa island_tow_speed, phanh trước đích (EconomyData) và đi vòng qua đảo khác
## chứ không xuyên qua. Thả ở chỗ hợp lệ thì hiện nút xác nhận kèm phí kéo (Profile.island_move_cost, trừ vàng trong trận):
## bấm dấu tích mới trả phí và mở bệ khi đảo tới nơi, bấm dấu nhân (hay thả chỗ không hợp lệ) thì đảo lai dắt về chỗ cũ,
## không tốn phí. Đảo có lô cốt thì không dời được. Đảo cấp sẵn của màn nằm cố định (mỗi màn sắp xếp riêng).

signal deployed(satellite_index: int)
signal pending_changed(satellite_index: int)
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
## Lưới chỗ đặt đảo: cạnh ô (đơn vị Godot), phần thụt vào mỗi cạnh để thấy khe lưới, độ cao so với mặt nước.
const GRID_CELL: float = 4.0
const GRID_INSET: float = 0.18
const GRID_Y: float = 0.5
const GRID_OK: Color = Color(0.25, 0.65, 1.0, 0.2)
const GRID_BAD: Color = Color(0.95, 0.25, 0.2, 0.24)
## Khe hở khi đi vòng qua đảo khác.
const AVOID_MARGIN: float = 2.0
## Thông báo ngắn (thiếu vàng) hiện chừng này giây.
const NOTICE_SECONDS: float = 2.0

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
## Đảo đã thả ở chỗ hợp lệ, đang chờ người chơi xác nhận trả phí (−1 nếu không có).
var _pending: int = -1
var _pending_spot: Vector3 = Vector3.ZERO
var _markers: MeshInstance3D
var _grid: MeshInstance3D
var _hint: Label
var _notice_left: float = 0.0
var _confirm: IconButton
var _cancel: IconButton


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
	_pending = -1
	if not is_instance_valid(_markers):
		_markers = MeshInstance3D.new()
		_markers.name = "IslandMarkers"
		_markers.material_override = Island.solid_material()
		battle.island.add_child(_markers)
	if not is_instance_valid(_grid):
		_grid = MeshInstance3D.new()
		_grid.name = "IslandGrid"
		_grid.material_override = _grid_material()
		_grid.visible = false
		battle.island.add_child(_grid)
	if _hint == null:
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


## Phí kéo đảo k: 60 nếu đảo trống, 180 nếu đảo đang mang lô cốt (lô cốt đi theo đảo); số theo giá lô cốt rẻ nhất.
func move_cost(satellite: int) -> int:
	return Profile.island_loaded_move_cost() if _pad_of(satellite).occupied else Profile.island_move_cost()


## Đảo đang chờ xác nhận, hoặc −1.
func pending_island() -> int:
	return _pending


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
	_pending = -1
	_rebuild_markers()
	changed.emit()


## Bắt đầu kéo nếu điểm chạm trúng một đảo mua thêm; trả true nếu bắt được.
func begin_drag(screen_position: Vector2) -> bool:
	var best: int = -1
	var best_distance: float = PICK_RADIUS
	for k: int in range(_free_count, battle.island.satellites.size()):
		var d: float = battle.camera.unproject_position(battle.layout.satellite_centers[k]).distance_to(screen_position)
		if d < best_distance:
			best_distance = d
			best = k
	if best < 0:
		return false
	if battle.economy.steel < move_cost(best):
		# Hết vàng thì không nhấc được đảo: báo rõ rồi coi như đã xử lý cử chỉ (không kéo camera).
		_notice(tr(&"ISLAND_NEED_GOLD") % move_cost(best))
		return true
	if _pending >= 0 and _pending != best:
		decline()
	_pending = -1
	_dragging = best
	_pad_of(best).locked = true
	_finger = battle.layout.satellite_centers[best]
	_finger_valid = false
	_goal[best] = _finger
	_rebuild_grid(best)
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


## Thả đảo: chỗ hợp lệ thì chờ xác nhận (đảo vẫn lai dắt tới chỗ đó cho xem trước), không thì lai dắt về chỗ cũ.
func end_drag() -> void:
	if _dragging < 0:
		return
	var k: int = _dragging
	_dragging = -1
	if _finger_valid:
		_pending = k
		_pending_spot = _finger
		_goal[k] = _finger
		pending_changed.emit(k)
	else:
		_goal[k] = home_of(k)
	_rebuild_markers()
	changed.emit()


## Xác nhận kéo đảo đang chờ: trừ phí kéo, đảo ở lại chỗ đã thả. Thiếu vàng thì không làm gì và báo rejected.
func confirm() -> bool:
	if _pending < 0:
		return false
	var k: int = _pending
	if not battle.economy.spend(move_cost(k)):
		rejected.emit()
		return false
	_pending = -1
	_home[k] = _pending_spot
	_placed[k] = true
	_goal[k] = _home[k]
	deployed.emit(k)
	pending_changed.emit(-1)
	Events.ui_clicked.emit()
	_rebuild_markers()
	changed.emit()
	return true


## Từ chối kéo đảo đang chờ: đảo lai dắt về chỗ cũ, không tốn phí.
func decline() -> void:
	if _pending < 0:
		return
	var k: int = _pending
	_pending = -1
	_goal[k] = home_of(k)
	pending_changed.emit(-1)
	_rebuild_markers()
	changed.emit()


## Huỷ kéo (chụm hai ngón): đảo lai dắt về chỗ cũ, không tốn phí.
func cancel() -> void:
	if _dragging < 0:
		return
	_goal[_dragging] = home_of(_dragging)
	_dragging = -1
	_finger_valid = false
	_pending = -1
	_rebuild_markers()


## Một bước lai dắt: tăng tốc dần về phía đích, đi vòng qua đảo khác, phanh sao cho vừa dừng đúng đích.
func tow_step(delta: float) -> void:
	if battle == null or _goal.is_empty():
		return
	var speed: float = Profile.economy_rules.island_tow_speed
	var accel: float = Profile.economy_rules.island_tow_accel
	_relayout_clock += delta
	for k: int in _goal.keys():
		var here: Vector3 = battle.layout.satellite_centers[k]
		var soft: Array[Vector4] = _obstacles(k, AVOID_MARGIN)
		var hard: Array[Vector4] = _obstacles(k, 0.0)
		var goal: Vector3 = clear_of_obstacles(_goal[k], hard)
		var waypoint: Vector3 = next_waypoint(here, goal, soft)
		var remaining: float = Vector2(waypoint.x - here.x, waypoint.z - here.z).length() + Vector2(goal.x - waypoint.x, goal.z - waypoint.z).length()
		var final: bool = waypoint == goal
		var step: Dictionary = tow_motion(here, _velocity.get(k, Vector3.ZERO), waypoint, speed, accel, delta, remaining, final)
		var arrived_now: bool = final and step["arrived"] and goal.is_equal_approx(_goal[k])
		# Lưới an toàn: quán tính không bao giờ đưa đảo chồng lên đảo khác, chạm vào thì trượt dọc mép.
		var slid: Dictionary = slide_out(step["position"], step["velocity"], hard)
		_velocity[k] = slid["velocity"]
		_place(k, _goal[k] if arrived_now else slid["position"], arrived_now and _dragging != k)
		if arrived_now:
			_finish_tow(k)
	if _relayout_clock >= RELAYOUT_INTERVAL:
		_relayout_clock = 0.0
		battle.island.relayout(battle.layout)
		battle.update_island_discs()


## Chuyển động lai dắt thuần: từ vị trí here, vận tốc velocity tới điểm goal, trong delta giây. Trả
## {"position", "velocity", "arrived"}. Tốc độ mong muốn là min(tốc độ tối đa, sqrt(2·gia tốc·quãng còn lại)) nên đảo
## nhấc bước dần và phanh êm; vận tốc đổi tối đa accel·delta mỗi bước. remaining là quãng còn lại tới đích cuối (mặc định
## bằng quãng tới goal); final = false khi goal chỉ là điểm đi vòng: không dừng, không báo tới nơi.
static func tow_motion(here: Vector3, velocity: Vector3, goal: Vector3, speed: float, accel: float, delta: float, remaining: float = -1.0, final: bool = true) -> Dictionary:
	var to_goal: Vector3 = goal - here
	to_goal.y = 0.0
	var distance: float = to_goal.length()
	if remaining < 0.0:
		remaining = distance
	if final and distance < ARRIVE_DISTANCE and velocity.length() < ARRIVE_SPEED:
		return {"position": goal, "velocity": Vector3.ZERO, "arrived": true}
	var wanted: Vector3 = Vector3.ZERO
	if distance > 0.0:
		wanted = to_goal / distance * minf(speed, sqrt(2.0 * accel * remaining))
	var next_velocity: Vector3 = velocity.move_toward(wanted, accel * delta)
	var travel: Vector3 = next_velocity * delta
	if final and travel.length() >= distance:
		return {"position": goal, "velocity": Vector3.ZERO, "arrived": true}
	return {"position": here + travel, "velocity": next_velocity, "arrived": false}


## Điểm đầu tiên cần hướng tới để đi từ here tới goal mà không cắt qua vật cản (mỗi vật cản là Vector4(x, z, bán kính, 0)).
## Đang nằm trong một vật cản thì đi ra khỏi nó trước. Đường bị chắn thì hướng tới tiếp điểm của tiếp tuyến vẽ từ here tới
## vật cản, phía cùng chiều với hướng đi; mỗi nhịp tính lại nên đảo bám mép vật cản rồi thoát ra đúng chỗ.
static func next_waypoint(here: Vector3, goal: Vector3, obstacles: Array[Vector4]) -> Vector3:
	var from: Vector2 = Vector2(here.x, here.z)
	var end: Vector2 = Vector2(goal.x, goal.z)
	for o: Vector4 in obstacles:
		var center: Vector2 = Vector2(o.x, o.y)
		if from.distance_to(center) < o.z and end.distance_to(center) >= o.z:
			var out: Vector2 = center + (from - center).normalized() * (o.z + 0.4) if from.distance_to(center) > 0.001 else center + Vector2.RIGHT * (o.z + 0.4)
			return Vector3(out.x, 0.0, out.y)
	var target: Vector2 = end
	for _attempt: int in 6:
		var hit: int = -1
		var hit_distance: float = INF
		for i: int in obstacles.size():
			var o: Vector4 = obstacles[i]
			var center: Vector2 = Vector2(o.x, o.y)
			if target.distance_to(center) < o.z or from.distance_to(center) < o.z:
				continue
			var closest: Vector2 = Geometry2D.get_closest_point_to_segment(center, from, target)
			if closest.distance_to(center) < o.z and from.distance_to(closest) < hit_distance:
				hit = i
				hit_distance = from.distance_to(closest)
		if hit < 0:
			break
		var c: Vector4 = obstacles[hit]
		var center: Vector2 = Vector2(c.x, c.y)
		var to_center: Vector2 = center - from
		var ring: float = c.z + 0.3
		var distance: float = to_center.length()
		var half: float = asin(clampf(ring / distance, 0.0, 1.0))
		var turn: float = 1.0 if to_center.cross(target - from) >= 0.0 else -1.0
		var tangent: Vector2 = from + to_center.normalized().rotated(half * turn) * sqrt(maxf(distance * distance - ring * ring, 0.25))
		target = tangent
	return Vector3(target.x, 0.0, target.y)


## Đẩy điểm point ra ngoài mọi vật cản chứa nó (để đảo dừng sát mép vật cản chứ không chui vào).
static func clear_of_obstacles(point: Vector3, obstacles: Array[Vector4]) -> Vector3:
	var result: Vector3 = point
	for o: Vector4 in obstacles:
		var center: Vector3 = Vector3(o.x, 0.0, o.y)
		var away: Vector3 = result - center
		away.y = 0.0
		if away.length() < o.z:
			var direction: Vector3 = away.normalized() if away.length() > 0.001 else Vector3.RIGHT
			result = center + direction * (o.z + 0.05)
	return result


## Đẩy vị trí position ra khỏi các vật cản (bán kính thật) và bỏ thành phần vận tốc đâm vào chúng.
static func slide_out(position: Vector3, velocity: Vector3, obstacles: Array[Vector4]) -> Dictionary:
	var result: Vector3 = position
	var speed: Vector3 = velocity
	for o: Vector4 in obstacles:
		var center: Vector3 = Vector3(o.x, 0.0, o.y)
		var away: Vector3 = result - center
		away.y = 0.0
		if away.length() < o.z:
			var normal: Vector3 = away.normalized() if away.length() > 0.001 else Vector3.RIGHT
			result = center + normal * o.z
			if speed.dot(normal) < 0.0:
				speed -= normal * speed.dot(normal)
	return {"position": result, "velocity": speed}


## Vật cản của đảo k: đảo chính (kể cả đầu mỏm bến) và các đảo vệ tinh khác, nở thêm bán kính đảo k và khe hở margin.
func _obstacles(k: int, margin: float) -> Array[Vector4]:
	var layout: MapLayout = battle.layout
	var result: Array[Vector4] = []
	var reach: float = layout.fortress_radius
	for i: int in layout.pad_count():
		if layout.is_pier_pad(i):
			reach = maxf(reach, Vector2(layout.pad_positions[i].x - layout.fortress_center.x, layout.pad_positions[i].z - layout.fortress_center.z).length() + AllianceFortress.PIER_END_RADIUS)
	result.append(Vector4(layout.fortress_center.x, layout.fortress_center.z, reach + layout.satellite_radius + margin, 0.0))
	for center: Vector3 in layout.platform_centers:
		result.append(Vector4(center.x, center.z, layout.platform_radius + layout.satellite_radius + margin, 0.0))
	for j: int in layout.satellite_centers.size():
		if j != k:
			result.append(Vector4(layout.satellite_centers[j].x, layout.satellite_centers[j].z, layout.satellite_radius * 2.0 + margin, 0.0))
	return result


func _finish_tow(k: int) -> void:
	_goal.erase(k)
	_velocity.erase(k)
	if _dragging == k:
		# Ngón tay còn giữ: đảo tới chỗ ngón tay chỉ nhưng vẫn đang kéo, giữ nguyên đích.
		_goal[k] = _finger
		return
	if _placed.has(k) and _pending != k:
		_pad_of(k).locked = false
		arrived.emit(k)
	_rebuild_markers()


## Hiện thông báo ngắn ở dòng chỉ dẫn (ví dụ thiếu vàng).
func _notice(text: String) -> void:
	if _hint == null:
		return
	_hint.text = text
	_hint.visible = true
	_notice_left = NOTICE_SECONDS


func _process(delta: float) -> void:
	if _notice_left > 0.0:
		_notice_left -= delta
		if _notice_left <= 0.0:
			_rebuild_markers()
	tow_step(delta)
	if _hint != null and battle != null and _notice_left <= 0.0:
		_hint.visible = (docked_count() > 0 or _pending >= 0) and not battle.is_over()
	_place_confirm()


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
		var color: Color = GRID_OK.lightened(0.2) if _finger_valid else GRID_BAD.lightened(0.1)
		color.a = 1.0
		MeshKit.ring(st, _finger, radius - 0.9, radius, 0.3, 0.55, 24, color, color)
	# Đảo còn đậu: viền cam quanh để biết kéo được.
	for k: int in range(_free_count, battle.island.satellites.size()):
		if not _placed.has(k) and k != _dragging and not _goal.has(k):
			var center: Vector3 = battle.layout.satellite_centers[k]
			MeshKit.ring(st, center, radius + 0.5, radius + 1.2, 0.3, 0.55, 24, UiStyle.RESCUE_ORANGE, UiStyle.RESCUE_ORANGE)
	if _pending >= 0 and _dragging < 0:
		var ok: Color = GRID_OK.lightened(0.2)
		ok.a = 1.0
		MeshKit.ring(st, _pending_spot, radius - 0.9, radius, 0.3, 0.55, 24, ok, ok)
	_markers.mesh = MeshKit.commit(st)
	if _grid != null:
		_grid.visible = _dragging >= 0 or _pending >= 0
	_refresh_confirm()
	if _hint != null and _notice_left <= 0.0:
		_hint.visible = (docked_count() > 0 or _pending >= 0) and not battle.is_over()
		_hint.text = tr(&"ISLAND_CONFIRM") % move_cost(_pending) if _pending >= 0 else tr(&"ISLAND_DEPLOY_HINT") % Profile.island_move_cost()


func _build_hint() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "HintLayer"
	add_child(layer)
	_confirm = IconButton.new()
	_confirm.name = "Confirm"
	_confirm.setup(IconButton.Kind.CHECK, UiStyle.RESCUE_ORANGE, UiStyle.PRIMARY_PRESSED)
	_confirm.pressed.connect(confirm)
	_confirm.visible = false
	layer.add_child(_confirm)
	_cancel = IconButton.new()
	_cancel.name = "Cancel"
	_cancel.setup(IconButton.Kind.CROSS, UiStyle.GRAPHITE.lightened(0.1), UiStyle.GRAPHITE.darkened(0.1))
	_cancel.pressed.connect(decline)
	_cancel.visible = false
	layer.add_child(_cancel)
	_hint = UiStyle.label(UiStyle.TEXT_SIZE - 6)
	_hint.name = "Hint"
	_hint.add_theme_color_override(&"font_color", UiStyle.RESCUE_ORANGE.lightened(0.3))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 48)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_hint)


## Hai nút tròn xác nhận (dấu tích) và huỷ (dấu nhân) chỉ hiện khi có đảo chờ xác nhận; nút xác nhận xám nếu thiếu vàng.
func _refresh_confirm() -> void:
	if _confirm == null:
		return
	var showing: bool = _pending >= 0 and _dragging < 0
	_confirm.visible = showing
	_cancel.visible = showing
	if showing:
		_confirm.disabled = battle.economy.steel < move_cost(_pending)
		_confirm.tooltip_text = tr(&"ISLAND_CONFIRM") % move_cost(_pending)
		_confirm.refresh_glyph()
		_place_confirm()


## Đặt cặp nút dưới đảo chờ xác nhận (theo vị trí đảo trên màn hình), ép vào trong màn hình.
func _place_confirm() -> void:
	if _confirm == null or not _confirm.visible or battle == null or _pending < 0:
		return
	var screen: Vector2 = _confirm.get_viewport_rect().size
	var anchor: Vector2 = battle.camera.unproject_position(battle.layout.satellite_centers[_pending])
	var pair: Vector2 = Vector2(IconButton.SIZE * 2.0 + 16.0, IconButton.SIZE)
	var left: Vector2 = anchor + Vector2(0.0, 140.0) - pair * 0.5
	left = Vector2(clampf(left.x, UiStyle.MARGIN, screen.x - pair.x - UiStyle.MARGIN), clampf(left.y, UiStyle.MARGIN, screen.y - pair.y - UiStyle.MARGIN))
	_cancel.position = left
	_confirm.position = left + Vector2(IconButton.SIZE + 16.0, 0.0)


## Lưới trên mặt biển: ô xanh là chỗ đặt được đảo ignore_index, ô đỏ là chỗ không.
func _rebuild_grid(ignore_index: int) -> void:
	_grid.mesh = build_grid(battle.layout, ignore_index)


static func build_grid(layout: MapLayout, ignore_index: int) -> ArrayMesh:
	var st: SurfaceTool = MeshKit.begin()
	var bounds: Rect2 = layout.camera_zoom_bounds.grow(-layout.satellite_radius)
	var x: float = bounds.position.x
	while x + GRID_CELL <= bounds.end.x:
		var z: float = bounds.position.y
		while z + GRID_CELL <= bounds.end.y:
			var center: Vector3 = Vector3(x + GRID_CELL * 0.5, 0.0, z + GRID_CELL * 0.5)
			var color: Color = GRID_OK if layout.island_spot_valid(center, ignore_index) else GRID_BAD
			var h: float = GRID_CELL * 0.5 - GRID_INSET
			var a: Vector3 = Vector3(center.x - h, GRID_Y, center.z - h)
			var b: Vector3 = Vector3(center.x + h, GRID_Y, center.z - h)
			var c: Vector3 = Vector3(center.x + h, GRID_Y, center.z + h)
			var d: Vector3 = Vector3(center.x - h, GRID_Y, center.z + h)
			MeshKit.tri(st, a, b, c, Vector3.UP, color, color, color)
			MeshKit.tri(st, a, c, d, Vector3.UP, color, color, color)
			z += GRID_CELL
		x += GRID_CELL
	return MeshKit.commit(st)


static func _grid_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.disable_receive_shadows = true
	return material

