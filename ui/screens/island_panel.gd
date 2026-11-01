class_name IslandPanel
extends PanelContainer
## Trang Đảo vệ tinh ở màn Căn cứ: số đảo sở hữu, phí kéo đảo ra trong trận, nút Mua đảo và Đặt lại đảo mua.
## Đảo mua rồi có mãi và nằm cạnh đảo chính; kéo ra ô nào là chọn trong trận (tốn phí kéo).

signal changed

const BUTTON_SIZE: Vector2 = Vector2(760, 130)

var _count: Label
var _move: Label
var _status: Label
var _buy: Button
var _reset: Button


func _ready() -> void:
	add_theme_stylebox_override(&"panel", UiStyle.panel_box())
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 14)
	add_child(column)
	_count = _line(column, UiStyle.TEXT_SIZE, UiStyle.IVORY)
	_move = _line(column, UiStyle.TEXT_SIZE - 6, UiStyle.GOLD.lightened(0.3))
	var hint: Label = _line(column, UiStyle.TEXT_SIZE - 12, Color(1, 1, 1, 0.8))
	hint.text = tr(&"BASE_ISLAND_HINT")
	_status = _line(column, UiStyle.TEXT_SIZE - 6, UiStyle.RESCUE_ORANGE.lightened(0.2))
	_buy = UiStyle.primary_button(&"", BUTTON_SIZE)
	_buy.add_theme_font_size_override(&"font_size", 40)
	_buy.pressed.connect(_on_buy)
	column.add_child(_buy)
	_reset = UiStyle.secondary_button(&"BASE_ISLAND_RESET", BUTTON_SIZE)
	_reset.add_theme_font_size_override(&"font_size", 36)
	_reset.pressed.connect(reset_islands)
	column.add_child(_reset)
	Profile.islands_changed.connect(refresh)
	Profile.gold_changed.connect(_on_gold)
	refresh()


func _exit_tree() -> void:
	if Profile.islands_changed.is_connected(refresh):
		Profile.islands_changed.disconnect(refresh)
	if Profile.gold_changed.is_connected(_on_gold):
		Profile.gold_changed.disconnect(_on_gold)


func buy_button() -> Button:
	return _buy


func reset_button() -> Button:
	return _reset


func count_text() -> String:
	return _count.text


func move_text() -> String:
	return _move.text


func status_text() -> String:
	return _status.text


func reset_islands() -> void:
	Profile.reset_islands()
	Profile.save()
	_status.text = ""
	changed.emit()


func refresh() -> void:
	if _count == null:
		return
	_count.text = tr(&"BASE_ISLAND_COUNT") % [Profile.island_total(), Profile.usable_bought_islands(), Profile.max_bought_islands()]
	_count.text += "\n" + tr(&"BASE_OUTPOST_LIMIT") % [Profile.outpost_total(), Profile.map().outpost_limit(Profile.difficulty), tr(Difficulty.name_key(Profile.difficulty))]
	_move.text = tr(&"BASE_ISLAND_MOVE") % Profile.island_move_cost()
	if Profile.usable_bought_islands() >= Profile.max_bought_islands():
		_buy.text = tr(&"BASE_ISLAND_BUY_MAX")
		_buy.disabled = true
	else:
		_buy.text = tr(&"BASE_ISLAND_BUY") % Profile.island_buy_cost()
		_buy.disabled = not Profile.can_buy_island()


func _on_buy() -> void:
	if Profile.buy_island():
		_status.text = tr(&"BASE_MSG_BOUGHT")
		changed.emit()


func _on_gold(_value: int) -> void:
	refresh()


func _line(parent: Control, size: int, color: Color) -> Label:
	var label: Label = UiStyle.label(size)
	label.add_theme_color_override(&"font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.custom_minimum_size = Vector2(760, 0)
	parent.add_child(label)
	return label
