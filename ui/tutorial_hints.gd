class_name TutorialHints
extends Control
## Hướng dẫn vài bước đầu (GDD mục 8.1, bản tháng 1): một dải chữ nhỏ dưới giữa màn hình dẫn người chơi qua bốn việc:
## chạm bệ, chọn lô cốt rồi chạm dấu tích để xây, nhìn đèn đỏ báo hướng địch, chạm lô cốt đang nhấp nháy để kích MEGA.
## Mỗi bước tự qua khi người chơi làm đúng việc (nghe Events); xong hết hoặc bấm Bỏ qua thì ghi Settings.tutorial_done.

signal finished

enum Step { PICK_PAD, BUILD, ENEMY, MEGA, DONE }

const TEXT_KEYS: Dictionary[Step, StringName] = {
	Step.PICK_PAD: &"HINT_PICK_PAD",
	Step.BUILD: &"HINT_BUILD",
	Step.ENEMY: &"HINT_ENEMY",
	Step.MEGA: &"HINT_MEGA",
}

var step: Step = Step.PICK_PAD
var build_ring: BuildRing

var _panel: PanelContainer
var _label: Label
var _skip: Button
## Bước MEGA chỉ hiện khi đã có lô cốt đầy thanh.
var _mega_ready: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = PanelContainer.new()
	_panel.name = "Hint"
	_panel.add_theme_stylebox_override(&"panel", UiStyle.panel_box())
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, UiStyle.MARGIN * 2)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_panel)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 24)
	_panel.add_child(row)
	_label = UiStyle.label(UiStyle.TEXT_SIZE - 4)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.custom_minimum_size = Vector2(780, 0)
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_label)
	_skip = UiStyle.secondary_button(&"HINT_SKIP", Vector2(180, 120))
	_skip.add_theme_font_size_override(&"font_size", 34)
	_skip.pressed.connect(skip)
	row.add_child(_skip)
	Events.tower_built.connect(_on_tower_built)
	Events.wave_started.connect(_on_wave_started)
	Events.overload_ready.connect(_on_overload_ready)
	Events.mega_started.connect(_on_mega_started)
	Events.battle_ended.connect(_on_battle_ended)
	_refresh()


func _process(_delta: float) -> void:
	if step == Step.PICK_PAD and build_ring != null and build_ring.is_open():
		_advance_to(Step.BUILD)


## Chữ đang hiện, rỗng nếu không có bước nào.
func current_text() -> String:
	return tr(TEXT_KEYS[step]) if TEXT_KEYS.has(step) else ""


func is_active() -> bool:
	return step != Step.DONE


func skip_button() -> Button:
	return _skip


## Bỏ qua toàn bộ hướng dẫn.
func skip() -> void:
	_finish()


func _advance_to(next: Step) -> void:
	if step == Step.DONE or next <= step:
		return
	step = next
	_refresh()


func _refresh() -> void:
	if _panel == null:
		return
	# Bước MEGA chỉ hiện khi có lô cốt sẵn sàng; bước ĐỊCH tự ẩn cho tới khi cần.
	_panel.visible = is_active() and (step != Step.MEGA or _mega_ready)
	_label.text = current_text()


func _finish() -> void:
	if step == Step.DONE and Settings.tutorial_done:
		return
	step = Step.DONE
	Settings.tutorial_done = true
	_refresh()
	finished.emit()


func _on_tower_built(_tower: Node3D) -> void:
	if step <= Step.BUILD:
		step = Step.BUILD
		_advance_to(Step.ENEMY)


func _on_wave_started(_index: int, _total: int) -> void:
	if step == Step.ENEMY:
		_advance_to(Step.MEGA)
		_refresh()


func _on_overload_ready(_tower: Node3D) -> void:
	_mega_ready = true
	if step == Step.ENEMY:
		step = Step.MEGA
	_refresh()


func _on_mega_started(_tower: Node3D) -> void:
	if step == Step.MEGA or _mega_ready:
		_finish()


func _on_battle_ended(_won: bool) -> void:
	if is_active():
		_finish()
