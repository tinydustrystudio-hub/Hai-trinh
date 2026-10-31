class_name BranchCards
extends Control
## Chọn nhánh cấp 5 (GDD mục 7.10): hai thẻ lớn cạnh nhau, 5A bên trái và 5B bên phải; mỗi thẻ có tên,
## một câu mô tả, kỹ năng và giá. Thiếu Thép thì thẻ xám. Nút Quay lại ở góc dưới trái.
## Trận chậm còn 30% trong lúc chọn (BattleController lo).

signal branch_chosen(branch: TowerBranch)
signal cancelled

const CARD_SIZE: Vector2 = Vector2(620, 560)
const GAP: float = 48.0

var tower: Tower = null

var _cards: Array[Button] = []
var _title: Label
var _back: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.5)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	_title = UiStyle.label(56)
	_title.text = &"BRANCH_TITLE"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_SIZE, 60)
	_title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(_title)
	_back = UiStyle.primary_button(&"BUTTON_BACK", Vector2(300, 130))
	_back.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, UiStyle.MARGIN * 2)
	_back.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_back.pressed.connect(cancelled.emit)
	add_child(_back)
	visible = false


func open(chosen: Tower, steel: int) -> void:
	tower = chosen
	for card: Button in _cards:
		card.queue_free()
	_cards.clear()
	var screen: Vector2 = get_viewport_rect().size
	var total: float = CARD_SIZE.x * 2.0 + GAP
	for i: int in chosen.data.branches.size():
		var option: TowerBranch = chosen.data.branches[i]
		var card: Button = UiStyle.primary_button(&"", CARD_SIZE)
		card.size = CARD_SIZE
		card.position = Vector2((screen.x - total) * 0.5 + float(i) * (CARD_SIZE.x + GAP), (screen.y - CARD_SIZE.y) * 0.5)
		card.add_theme_font_size_override(&"font_size", 34)
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.text = "%s %s\n\n%s\n\n%s: %s\n\n%d" % [
			"5A" if i == 0 else "5B", tr(option.name_key), tr(option.description_key),
			tr(option.skill_name_key), tr(option.skill_description_key), option.steel_cost]
		var affordable: bool = option.steel_cost <= steel
		card.disabled = not affordable
		card.pressed.connect(_on_card_pressed.bind(option))
		add_child(card)
		_cards.append(card)
	visible = true


func close() -> void:
	visible = false
	tower = null


func is_open() -> bool:
	return visible


func cards() -> Array[Button]:
	return _cards


func _on_card_pressed(option: TowerBranch) -> void:
	branch_chosen.emit(option)
