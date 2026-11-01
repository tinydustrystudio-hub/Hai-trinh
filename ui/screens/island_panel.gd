class_name IslandPanel
extends PanelContainer
## Trang Đảo vệ tinh ở màn Căn cứ: số đảo sở hữu và đã đặt, phí dùng mỗi trận, phí dời, nút Mua đảo, Cất đảo, Đặt lại đảo.
## Chạm ô trên bản đồ xem trước thì gọi tap_slot: ô trống đặt đảo từ kho (miễn phí) hoặc dời đảo đang chọn (tốn phí dời);
## ô có đảo thì chọn đảo đó.

signal changed
## Thông báo ngắn sau mỗi thao tác (đã đặt, đã dời, thiếu vàng…).
signal message(text: String)

const BUTTON_SIZE: Vector2 = Vector2(760, 130)

## Đảo đang được chọn (chỉ số trong Profile.islands), −1 nếu không.
var selected_island: int = -1

var _count: Label
var _fee: Label
var _move: Label
var _status: Label
var _buy: Button
var _store: Button
var _reset: Button


func _ready() -> void:
	add_theme_stylebox_override(&"panel", UiStyle.panel_box())
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 14)
	add_child(column)
	_count = _line(column, UiStyle.TEXT_SIZE, UiStyle.IVORY)
	_fee = _line(column, UiStyle.TEXT_SIZE - 6, UiStyle.GOLD.lightened(0.3))
	_move = _line(column, UiStyle.TEXT_SIZE - 6, UiStyle.GOLD.lightened(0.3))
	var hint: Label = _line(column, UiStyle.TEXT_SIZE - 12, Color(1, 1, 1, 0.8))
	hint.text = tr(&"BASE_ISLAND_HINT")
	_status = _line(column, UiStyle.TEXT_SIZE - 6, UiStyle.RESCUE_ORANGE.lightened(0.2))
	_buy = UiStyle.primary_button(&"", BUTTON_SIZE)
	_buy.add_theme_font_size_override(&"font_size", 40)
	_buy.pressed.connect(_on_buy)
	column.add_child(_buy)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 16)
	column.add_child(row)
	_store = UiStyle.secondary_button(&"BASE_ISLAND_STORE", Vector2(372, 130))
	_store.add_theme_font_size_override(&"font_size", 36)
	_store.pressed.connect(store_selected)
	row.add_child(_store)
	_reset = UiStyle.secondary_button(&"BASE_ISLAND_RESET", Vector2(372, 130))
	_reset.add_theme_font_size_override(&"font_size", 36)
	_reset.pressed.connect(reset_islands)
	row.add_child(_reset)
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


func store_button() -> Button:
	return _store


func reset_button() -> Button:
	return _reset


func count_text() -> String:
	return _count.text


func fee_text() -> String:
	return _fee.text


func status_text() -> String:
	return _status.text


## Chạm ô slot trên bản đồ xem trước.
func tap_slot(slot: int) -> void:
	var owner_island: int = Profile.island_at_slot(slot)
	if owner_island >= 0:
		selected_island = -1 if selected_island == owner_island else owner_island
		_say("")
		changed.emit()
		return
	if selected_island >= 0 and Profile.islands[selected_island] >= 0:
		var fee: int = Profile.island_move_cost()
		if Profile.place_island(selected_island, slot):
			_say(tr(&"BASE_MSG_MOVED") % fee)
		else:
			_say(tr(&"BASE_MSG_NO_GOLD"))
		changed.emit()
		return
	var stored: int = Profile.first_stored_island()
	if stored < 0:
		_say(tr(&"BASE_MSG_NO_STOCK"))
	elif Profile.place_island(stored, slot):
		selected_island = stored
		_say(tr(&"BASE_MSG_PLACED"))
	else:
		_say(tr(&"BASE_MSG_LIMIT") % Profile.max_placed())
	changed.emit()


func store_selected() -> void:
	if selected_island >= 0 and Profile.store_island(selected_island):
		selected_island = -1
		_say(tr(&"BASE_MSG_STORED"))
		changed.emit()


func reset_islands() -> void:
	Profile.reset_islands()
	Profile.save()
	selected_island = -1
	_say("")
	changed.emit()


func refresh() -> void:
	if _count == null:
		return
	_count.text = tr(&"BASE_ISLAND_COUNT") % [Profile.island_total(), Profile.placed_count(), Profile.max_placed()]
	var placed: Array[int] = []
	for island: int in Profile.islands.size():
		if Profile.islands[island] >= 0:
			placed.append(island)
	_fee.text = tr(&"BASE_ISLAND_FEE") % Profile.use_fee(placed)
	_move.text = tr(&"BASE_ISLAND_MOVE") % Profile.island_move_cost()
	if Profile.bought_islands >= Profile.max_bought_islands():
		_buy.text = tr(&"BASE_ISLAND_BUY_MAX")
		_buy.disabled = true
	else:
		_buy.text = tr(&"BASE_ISLAND_BUY") % Profile.island_buy_cost()
		_buy.disabled = not Profile.can_buy_island()
	_store.disabled = selected_island < 0


func _on_buy() -> void:
	if Profile.buy_island():
		_say(tr(&"BASE_MSG_BOUGHT"))
		changed.emit()


func _on_gold(_value: int) -> void:
	refresh()


func _say(text: String) -> void:
	_status.text = text
	message.emit(text)
	refresh()


func _line(parent: Control, size: int, color: Color) -> Label:
	var label: Label = UiStyle.label(size)
	label.add_theme_color_override(&"font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.custom_minimum_size = Vector2(760, 0)
	parent.add_child(label)
	return label
