class_name Hud
extends CanvasLayer
## HUD trận. Hiện có Độ Nổi, đợt hiện tại, báo đợt sắp tới, Thép (trên phải), vòng chọn lô cốt,
## vòng nâng cấp, thẻ chọn nhánh, khay MEGA (dưới phải) và màn kết quả; Tạm dừng và ×2 thêm ở bước 11. Chỉ nghe Events.

signal retry_requested

var _buoyancy: Label
var _wave: Label
var _incoming: Label
var _steel: Label
var _wave_total: int = 0

@onready var result_panel: ResultPanel = $ResultPanel
@onready var build_ring: BuildRing = $BuildRing
@onready var upgrade_ring: UpgradeRing = $UpgradeRing
@onready var branch_cards: BranchCards = $BranchCards
@onready var mega_tray: MegaTray = $MegaTray


func _ready() -> void:
	var top_left: VBoxContainer = VBoxContainer.new()
	top_left.position = Vector2(UiStyle.MARGIN, UiStyle.MARGIN)
	add_child(top_left)
	move_child(top_left, 0)
	_buoyancy = UiStyle.label()
	_wave = UiStyle.label()
	top_left.add_child(_buoyancy)
	top_left.add_child(_wave)
	_incoming = UiStyle.label()
	_incoming.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_SIZE, UiStyle.MARGIN)
	_incoming.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_incoming.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(_incoming)
	move_child(_incoming, 1)
	_steel = UiStyle.label(UiStyle.TEXT_SIZE + 4)
	_steel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_KEEP_SIZE, UiStyle.MARGIN)
	_steel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_steel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(_steel)
	move_child(_steel, 2)
	result_panel.retry_requested.connect(retry_requested.emit)
	Events.steel_changed.connect(_on_steel_changed)
	Events.buoyancy_changed.connect(_on_buoyancy_changed)
	Events.wave_started.connect(_on_wave_started)
	Events.wave_incoming.connect(_on_wave_incoming)
	Events.wave_cleared.connect(_on_wave_cleared)


func show_result(won: bool) -> void:
	_incoming.text = ""
	result_panel.show_result(won)


func hide_result() -> void:
	result_panel.visible = false
	_wave.text = ""
	_incoming.text = ""


func buoyancy_text() -> String:
	return _buoyancy.text


func wave_text() -> String:
	return _wave.text


func steel_text() -> String:
	return _steel.text


func incoming_text() -> String:
	return _incoming.text


func _on_steel_changed(value: int) -> void:
	_steel.text = tr(&"HUD_STEEL") % value
	build_ring.set_steel(value)
	upgrade_ring.set_steel(value)


func _on_buoyancy_changed(value: int, max_value: int) -> void:
	_buoyancy.text = tr(&"HUD_BUOYANCY") % [value, max_value]


func _on_wave_started(index: int, total: int) -> void:
	_wave_total = total
	_wave.text = tr(&"HUD_WAVE") % [index + 1, total]
	_incoming.text = ""


func _on_wave_cleared(_index: int) -> void:
	_incoming.text = ""


func _on_wave_incoming(index: int, lane_indices: PackedInt32Array, seconds: float) -> void:
	var names: PackedStringArray = PackedStringArray()
	var battle: BattleController = owner as BattleController
	for lane_index: int in lane_indices:
		if battle != null and lane_index < battle.lanes.size():
			names.append(tr(battle.lanes[lane_index].name_key))
	_incoming.text = tr(&"HUD_NEXT_WAVE") % [index + 1, ceili(seconds), ", ".join(names)]
