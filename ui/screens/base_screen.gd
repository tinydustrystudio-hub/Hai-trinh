class_name BaseScreen
extends Control
## Màn Căn cứ (P5b): xem đảo chính ở bên trái (hình 3D đổi theo cấp công trình) và nâng cấp bốn công trình bằng Tiền Vàng
## ở bên phải. Ví hiện ở góc trên phải. Nút Chuẩn bị trận ở góc dưới phải (hành động chính), Quay lại ở góc dưới trái.
## Đảo vệ tinh (đặt, dời, mua) thêm ở bước sau.

signal play_requested
signal back_requested

const PLAY_SIZE: Vector2 = Vector2(560, 170)
const UPGRADE_SIZE: Vector2 = Vector2(300, 130)
const PREVIEW_SIZE: Vector2i = Vector2i(900, 760)
const LAYOUT_PATH: String = "res://data/maps/north_dock_layout.tres"

var _wallet: Label
var _rows: Dictionary[StringName, Dictionary] = {}
var _go: Button
var _back: Button
var _island: Island
var _layout: MapLayout


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop: MenuBackdrop = MenuBackdrop.new()
	backdrop.name = "Backdrop"
	add_child(backdrop)
	var title: Label = UiStyle.label(UiStyle.TITLE_SIZE - 16)
	title.name = "Title"
	title.text = tr(&"BASE_TITLE")
	title.add_theme_color_override(&"font_color", UiStyle.IVORY)
	title.position = Vector2(UiStyle.MARGIN * 2, UiStyle.MARGIN)
	add_child(title)
	_add_wallet()
	_add_preview()
	_add_building_list()
	_go = UiStyle.primary_button(&"BASE_GO", PLAY_SIZE)
	_go.name = "Go"
	_go.add_theme_font_size_override(&"font_size", 56)
	_go.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, UiStyle.MARGIN * 2)
	_go.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_go.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_go.pressed.connect(play_requested.emit)
	add_child(_go)
	_back = UiStyle.secondary_button(&"BUTTON_BACK", Vector2(320, 140))
	_back.name = "Back"
	_back.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, UiStyle.MARGIN * 2)
	_back.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_back.pressed.connect(back_requested.emit)
	add_child(_back)
	Profile.gold_changed.connect(_on_gold_changed)
	refresh()


func _exit_tree() -> void:
	if Profile.gold_changed.is_connected(_on_gold_changed):
		Profile.gold_changed.disconnect(_on_gold_changed)


func play_button() -> Button:
	return _go


func back_button() -> Button:
	return _back


func upgrade_button(id: StringName) -> Button:
	return _rows[id]["button"] as Button


func level_text(id: StringName) -> String:
	return (_rows[id]["level"] as Label).text


func wallet_text() -> String:
	return _wallet.text


func island() -> Island:
	return _island


## Cập nhật ví, cấp và nút nâng cấp của từng công trình, dựng lại đảo xem trước.
func refresh() -> void:
	_wallet.text = str(Profile.gold)
	for id: StringName in _rows:
		var row: Dictionary = _rows[id]
		(row["level"] as Label).text = tr(&"BASE_LEVEL") % [Profile.level_of(id), BuildingData.MAX_LEVEL]
		var button: Button = row["button"] as Button
		if Profile.is_max_level(id):
			button.text = tr(&"BASE_MAX")
			button.disabled = true
		else:
			button.text = tr(&"BASE_UPGRADE") % Profile.upgrade_cost(id)
			button.disabled = not Profile.can_upgrade(id)
	_rebuild_island()


func _on_upgrade(id: StringName) -> void:
	if Profile.upgrade(id):
		refresh()


func _on_gold_changed(_value: int) -> void:
	_wallet.text = str(Profile.gold)


func _add_wallet() -> void:
	var box: HBoxContainer = HBoxContainer.new()
	box.name = "Wallet"
	box.add_theme_constant_override(&"separation", 12)
	var coin: CoinIcon = CoinIcon.new()
	coin.custom_minimum_size = Vector2(CoinIcon.SIZE + 8.0, CoinIcon.SIZE + 8.0)
	box.add_child(coin)
	_wallet = UiStyle.label(UiStyle.TEXT_SIZE + 16)
	_wallet.name = "Gold"
	_wallet.add_theme_color_override(&"font_color", UiStyle.GOLD.lightened(0.3))
	box.add_child(_wallet)
	box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, UiStyle.MARGIN * 2)
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(box)


func _add_building_list() -> void:
	var card: PanelContainer = PanelContainer.new()
	card.name = "Buildings"
	card.add_theme_stylebox_override(&"panel", UiStyle.panel_box())
	card.position = Vector2(1000, 150)
	add_child(card)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 14)
	card.add_child(column)
	for data: BuildingData in Profile.buildings():
		var row: HBoxContainer = HBoxContainer.new()
		row.name = String(data.id)
		row.add_theme_constant_override(&"separation", 20)
		column.add_child(row)
		var text: VBoxContainer = VBoxContainer.new()
		text.custom_minimum_size = Vector2(520, 0)
		row.add_child(text)
		var name_label: Label = UiStyle.label(UiStyle.TEXT_SIZE)
		name_label.text = tr(data.name_key)
		name_label.add_theme_color_override(&"font_color", UiStyle.IVORY)
		text.add_child(name_label)
		var level: Label = UiStyle.label(UiStyle.TEXT_SIZE - 8)
		level.add_theme_color_override(&"font_color", UiStyle.GOLD.lightened(0.3))
		text.add_child(level)
		var hint: Label = UiStyle.label(UiStyle.TEXT_SIZE - 14)
		hint.text = tr(data.description_key)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD
		hint.modulate = Color(1, 1, 1, 0.8)
		text.add_child(hint)
		var button: Button = UiStyle.primary_button(&"", UPGRADE_SIZE)
		button.add_theme_font_size_override(&"font_size", 40)
		button.pressed.connect(_on_upgrade.bind(data.id))
		row.add_child(button)
		_rows[data.id] = {"level": level, "button": button}


func _add_preview() -> void:
	_layout = load(LAYOUT_PATH) as MapLayout
	var container: SubViewportContainer = SubViewportContainer.new()
	container.name = "Preview"
	container.stretch = true
	container.custom_minimum_size = Vector2(PREVIEW_SIZE)
	container.position = Vector2(UiStyle.MARGIN * 2, 150)
	add_child(container)
	var viewport: SubViewport = SubViewport.new()
	viewport.size = PREVIEW_SIZE
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	container.add_child(viewport)
	var center: Vector3 = _layout.fortress_center
	var camera: Camera3D = Camera3D.new()
	camera.fov = 35.0
	viewport.add_child(camera)
	camera.look_at_from_position(center + Vector3(0.0, 64.0, 55.0), center + Vector3(0.0, 2.0, 0.0))
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.light_energy = 1.1
	viewport.add_child(sun)
	sun.look_at_from_position(Vector3.ZERO, -_layout.sun_direction)
	var environment: Environment = Environment.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.7, 0.78, 0.9)
	environment.ambient_light_energy = 0.6
	var world: WorldEnvironment = WorldEnvironment.new()
	world.environment = environment
	viewport.add_child(world)
	_island = Island.new()
	_island.name = "Island"
	viewport.add_child(_island)


func _rebuild_island() -> void:
	if _island == null:
		return
	var layout: MapLayout = _layout.duplicate() as MapLayout
	layout.building_levels = Profile.building_levels.duplicate()
	_island.build(layout)
