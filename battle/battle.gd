class_name BattleController
extends Node3D
## Điều khiển trận. Bước 3: nạp MapLayout, dựng nước, đảo, bệ, luồng và camera;
## chạm bệ thì chọn bệ, kéo thì trượt camera.

const LANE_SCRIPT: GDScript = preload("res://battle/map/lane.gd")
## Chạm cách tâm bệ trong khoảng này (tính theo bán kính bệ) vẫn tính là chạm trúng bệ.
const PAD_PICK_TOLERANCE: float = 1.4

@export var layout: MapLayout = preload("res://data/maps/north_dock_layout.tres")

var lanes: Array[Lane] = []
var selected_pad: TowerPad = null

@onready var ocean: Ocean = $Ocean
@onready var island: Island = $Island
@onready var lanes_root: Node3D = $Lanes
@onready var camera: BattleCamera = $BattleCamera
@onready var touch_input: TouchInput = $Systems/TouchInput


func _ready() -> void:
	build_map()
	touch_input.tapped.connect(_on_tapped)
	touch_input.drag_started.connect(camera.begin_drag)
	touch_input.drag_moved.connect(camera.drag_to)
	touch_input.drag_ended.connect(_on_drag_ended)


func _process(_delta: float) -> void:
	TowerPad.animate_glow(float(Time.get_ticks_msec()) / 1000.0)


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


func select_pad(pad: TowerPad) -> void:
	if selected_pad != null:
		selected_pad.selected = false
	selected_pad = pad
	if pad != null:
		pad.selected = true


func _on_tapped(screen_position: Vector2) -> void:
	var point: Vector3 = camera.ground_point(screen_position, TowerPad.TOP_HEIGHT)
	var pad: TowerPad = island.pad_near(point, TowerPad.RADIUS * PAD_PICK_TOLERANCE)
	select_pad(pad if pad != selected_pad else null)


func _on_drag_ended(_screen_position: Vector2) -> void:
	camera.end_drag()
