class_name BattleCamera
extends Camera3D
## Camera trận: nghiêng cố định (55° theo GDD), không xoay. Kéo một ngón để trượt trong giới hạn
## của MapLayout; điểm nước dưới ngón tay luôn bám theo ngón tay. Thả tay thì trượt tiếp có quán tính nhẹ.
## Dùng đồng hồ thật thay cho delta, để vẫn mượt khi trận tạm dừng hoặc tua ×2.

## Quán tính tắt dần theo hàm mũ: vận tốc nhân e^(−DAMPING·t).
const DAMPING: float = 6.0
## Dưới tốc độ này (đơn vị/giây) thì dừng hẳn.
const MIN_SPEED: float = 0.5
## Không có chuyển động trong khoảng này (giây) trước khi thả thì không trượt tiếp.
const RELEASE_STILL_TIME: float = 0.08
## Hệ số làm mượt khi ước lượng vận tốc kéo.
const VELOCITY_SMOOTHING: float = 0.35
const FIELD_OF_VIEW: float = 40.0

## Điểm nhìn trên mặt nước (x, z).
var focus: Vector2 = Vector2.ZERO
var bounds: Rect2 = Rect2(-40.0, -40.0, 80.0, 60.0)
var distance: float = 60.0
var pitch_degrees: float = 55.0
var velocity: Vector2 = Vector2.ZERO

var _dragging: bool = false
var _drag_anchor: Vector3 = Vector3.ZERO
var _last_move_usec: int = 0
var _last_tick_usec: int = 0


func configure(layout: MapLayout) -> void:
	bounds = layout.camera_bounds
	distance = layout.camera_distance
	pitch_degrees = layout.camera_pitch_degrees
	fov = FIELD_OF_VIEW
	velocity = Vector2.ZERO
	set_focus(layout.camera_start)


func set_focus(value: Vector2) -> void:
	focus = clamp_focus(value, bounds)
	var pitch: float = deg_to_rad(pitch_degrees)
	rotation = Vector3(-pitch, 0.0, 0.0)
	position = Vector3(focus.x, 0.0, focus.y) + Vector3(0.0, sin(pitch), cos(pitch)) * distance


## Điểm trên mặt phẳng nước (độ cao height) nằm dưới một điểm trên màn hình.
func ground_point(screen_position: Vector2, height: float = 0.0) -> Vector3:
	return ray_to_plane(project_ray_origin(screen_position), project_ray_normal(screen_position), height)


func begin_drag(screen_position: Vector2) -> void:
	_dragging = true
	velocity = Vector2.ZERO
	_drag_anchor = ground_point(screen_position)
	_last_move_usec = Time.get_ticks_usec()


func drag_to(screen_position: Vector2) -> void:
	if not _dragging:
		return
	var now: int = Time.get_ticks_usec()
	var under_finger: Vector3 = ground_point(screen_position)
	var before: Vector2 = focus
	set_focus(focus + Vector2(_drag_anchor.x - under_finger.x, _drag_anchor.z - under_finger.z))
	var dt: float = maxf(float(now - _last_move_usec) / 1_000_000.0, 0.001)
	velocity = velocity.lerp((focus - before) / dt, VELOCITY_SMOOTHING)
	_last_move_usec = now


func end_drag() -> void:
	if not _dragging:
		return
	_dragging = false
	var still_for: float = float(Time.get_ticks_usec() - _last_move_usec) / 1_000_000.0
	if still_for > RELEASE_STILL_TIME:
		velocity = Vector2.ZERO


func is_dragging() -> bool:
	return _dragging


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	var dt: float = 0.0 if _last_tick_usec == 0 else float(now - _last_tick_usec) / 1_000_000.0
	_last_tick_usec = now
	if _dragging or velocity == Vector2.ZERO:
		return
	step_inertia(minf(dt, 0.1))


## Trượt tiếp theo quán tính trong dt giây.
func step_inertia(dt: float) -> void:
	var target: Vector2 = focus + velocity * dt
	set_focus(target)
	# Chạm biên thì triệt vận tốc theo chiều đó, tránh "dính" vào biên.
	if not is_equal_approx(focus.x, target.x):
		velocity.x = 0.0
	if not is_equal_approx(focus.y, target.y):
		velocity.y = 0.0
	velocity = apply_damping(velocity, dt, DAMPING, MIN_SPEED)


static func apply_damping(v: Vector2, dt: float, damping: float, min_speed: float) -> Vector2:
	var damped: Vector2 = v * exp(-damping * dt)
	return Vector2.ZERO if damped.length() < min_speed else damped


static func clamp_focus(value: Vector2, area: Rect2) -> Vector2:
	return Vector2(
		clampf(value.x, area.position.x, area.end.x),
		clampf(value.y, area.position.y, area.end.y))


## Giao của tia với mặt phẳng ngang y = height. Tia song song hoặc hướng lên thì trả về gốc tia chiếu xuống.
static func ray_to_plane(origin: Vector3, direction: Vector3, height: float) -> Vector3:
	if direction.y > -0.0001:
		return Vector3(origin.x, height, origin.z)
	var t: float = (height - origin.y) / direction.y
	return origin + direction * t
