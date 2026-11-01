class_name PrepScreen
extends Control
## Màn Chuẩn bị trận (GDD mục 7.9, bản tháng 1): tên bản đồ, mục tiêu, số đợt, Tiền Vàng khởi đầu, các loại địch sẽ
## gặp và các lô cốt dùng được kèm giá. Nút Xuất kích ở góc dưới phải; Quay lại ở góc dưới trái.

signal start_requested
signal back_requested

const GO_SIZE: Vector2 = Vector2(480, 170)

var layout: MapLayout
var wave_data: WaveData
var towers: Array[TowerData] = []

var _go: Button
var _back: Button


## Nạp dữ liệu bản đồ, các đợt và lô cốt trước khi vào cây.
func setup(map_layout: MapLayout, waves: WaveData, tower_list: Array[TowerData]) -> void:
	layout = map_layout
	wave_data = waves
	towers = tower_list


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop: MenuBackdrop = MenuBackdrop.new()
	backdrop.name = "Backdrop"
	add_child(backdrop)
	var title: Label = UiStyle.label(UiStyle.TITLE_SIZE - 16)
	title.name = "Title"
	title.text = tr(&"PREP_TITLE")
	title.add_theme_color_override(&"font_color", UiStyle.IVORY)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_KEEP_SIZE, 50)
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(title)
	var card: PanelContainer = PanelContainer.new()
	card.name = "Card"
	card.add_theme_stylebox_override(&"panel", UiStyle.panel_box())
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	card.offset_top += 40
	add_child(card)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override(&"separation", 60)
	card.add_child(columns)
	columns.add_child(_summary_column())
	columns.add_child(_list_column(tr(&"PREP_ENEMIES"), enemy_lines()))
	columns.add_child(_list_column(tr(&"PREP_TOWERS"), tower_lines()))
	_go = UiStyle.primary_button(&"PREP_GO", GO_SIZE)
	_go.name = "Go"
	_go.add_theme_font_size_override(&"font_size", 60)
	_go.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, UiStyle.MARGIN * 2)
	_go.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_go.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_go.pressed.connect(start_requested.emit)
	add_child(_go)
	_back = UiStyle.secondary_button(&"BUTTON_BACK", Vector2(320, 140))
	_back.name = "Back"
	_back.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, UiStyle.MARGIN * 2)
	_back.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_back.pressed.connect(back_requested.emit)
	add_child(_back)


## Tên các loại địch có trong mọi đợt, theo thứ tự gặp.
func enemy_lines() -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	var seen: Array[EnemyData] = []
	if wave_data != null:
		for wave: Wave in wave_data.waves:
			for group: SpawnGroup in wave.groups:
				if group.enemy != null and not seen.has(group.enemy):
					seen.append(group.enemy)
					lines.append(tr(group.enemy.name_key))
	return lines


## "Tên lô cốt – giá" cho từng lô cốt dùng được.
func tower_lines() -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	for data: TowerData in towers:
		lines.append("%s – %d" % [tr(data.name_key), data.level(1).steel_cost])
	return lines


func start_button() -> Button:
	return _go


func back_button() -> Button:
	return _back


func _summary_column() -> Control:
	var column: VBoxContainer = VBoxContainer.new()
	column.name = "Summary"
	column.add_theme_constant_override(&"separation", 18)
	var map_name: Label = UiStyle.label(UiStyle.TEXT_SIZE + 4)
	map_name.name = "MapName"
	map_name.text = tr(layout.name_key) if layout != null else ""
	map_name.add_theme_color_override(&"font_color", UiStyle.GOLD.lightened(0.3))
	column.add_child(map_name)
	var objective: Label = UiStyle.label(UiStyle.TEXT_SIZE - 4)
	objective.name = "Objective"
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD
	objective.custom_minimum_size = Vector2(520, 0)
	objective.text = tr(&"OBJECTIVE_HOLD") % (wave_data.wave_count() if wave_data != null else 0)
	column.add_child(objective)
	var gold_row: HBoxContainer = HBoxContainer.new()
	gold_row.add_theme_constant_override(&"separation", 12)
	var coin: CoinIcon = CoinIcon.new()
	coin.custom_minimum_size = Vector2(CoinIcon.SIZE, CoinIcon.SIZE)
	gold_row.add_child(coin)
	var gold: Label = UiStyle.label(UiStyle.TEXT_SIZE)
	gold.name = "Gold"
	gold.text = tr(&"PREP_GOLD") % (layout.starting_steel if layout != null else 0)
	gold_row.add_child(gold)
	column.add_child(gold_row)
	return column


func _list_column(heading: String, lines: PackedStringArray) -> Control:
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 14)
	var head: Label = UiStyle.label(UiStyle.TEXT_SIZE)
	head.text = heading
	head.add_theme_color_override(&"font_color", UiStyle.GOLD.lightened(0.3))
	column.add_child(head)
	for line: String in lines:
		var label: Label = UiStyle.label(UiStyle.TEXT_SIZE - 6)
		label.text = line
		column.add_child(label)
	return column
