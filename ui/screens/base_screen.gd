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
## Xoay: radian mỗi pixel kéo.
## Khoảng nghiêng cho phép (gần như nằm ngang tới nhìn thẳng xuống) và góc mặc định.
const MIN_PITCH: float = deg_to_rad(12.0)
const MAX_PITCH: float = deg_to_rad(88.0)
const DEFAULT_PITCH: float = 0.86088
## Khoảng cách camera tới tâm đảo ở hệ số 1.
const CAMERA_RADIUS: float = 84.38
const ROTATE_SPEED: float = 0.008
## Giới hạn phóng to, thu nhỏ khung xem trước (hệ số khoảng cách camera) và bước mỗi nấc lăn chuột.
const MIN_DISTANCE: float = 0.35
const MAX_DISTANCE: float = 1.3
const WHEEL_STEP: float = 1.12
## Vàng cộng thêm của nút thử nghiệm.
const TEST_GOLD: int = 1000
## Trang Đảo lùi camera ra xa hơn để thấy các đảo vệ tinh cạnh đảo chính.
const ISLAND_PAGE_DISTANCE: float = 1.5
const LAYOUT_PATH: String = "res://data/maps/north_dock_layout.tres"

var _wallet: Label
var _rows: Dictionary[StringName, Dictionary] = {}
var _go: Button
var _back: Button
var _island: Island
var _layout: MapLayout
var _camera: Camera3D
## Góc xoay của camera quanh đảo (radian), kéo ngón tay để xoay.
var _yaw: float = 0.0
## Góc nghiêng của camera so với mặt nước (radian), kéo ngón tay lên xuống để nghiêng.
var _pitch: float = DEFAULT_PITCH
## Hệ số khoảng cách camera (nhỏ hơn 1 là phóng to).
var _distance: float = 1.0
## Vị trí các ngón đang chạm vào khung xem trước, để nhận cử chỉ chụm hai ngón.
var _fingers: Dictionary[int, Vector2] = {}
var _reset_gold: Button
var _reset_levels: Button
var _add_gold: Button
var _buildings_card: PanelContainer
var _island_panel: IslandPanel
var _tab_buildings: Button
var _tab_islands: Button
## Trang đang mở: 0 công trình, 1 đảo vệ tinh.
var _page: int = 0


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
	_add_island_panel()
	_add_tabs()
	_add_test_buttons()
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
	_set_page(0)
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


func reset_gold_button() -> Button:
	return _reset_gold


func reset_levels_button() -> Button:
	return _reset_levels


func add_gold_button() -> Button:
	return _add_gold


func yaw() -> float:
	return _yaw


## Xoay đảo xem trước một góc (radian), camera quay quanh tâm đảo.
func rotate_preview(delta_yaw: float) -> void:
	_yaw = wrapf(_yaw + delta_yaw, -PI, PI)
	_place_camera()


func pitch() -> float:
	return _pitch


## Nghiêng góc nhìn (radian, dương là nhìn cao hơn, gần thẳng xuống).
func tilt_preview(delta_pitch: float) -> void:
	_pitch = clampf(_pitch + delta_pitch, MIN_PITCH, MAX_PITCH)
	_place_camera()


func distance_factor() -> float:
	return _distance


## Phóng to (factor > 1) hoặc thu nhỏ khung xem trước.
func zoom_preview(factor: float) -> void:
	if factor <= 0.0:
		return
	_distance = clampf(_distance / factor, MIN_DISTANCE, MAX_DISTANCE)
	_place_camera()


func page() -> int:
	return _page


func tab_buildings_button() -> Button:
	return _tab_buildings


func tab_islands_button() -> Button:
	return _tab_islands


func island_panel() -> IslandPanel:
	return _island_panel


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


func _add_island_panel() -> void:
	_island_panel = IslandPanel.new()
	_island_panel.name = "IslandPanel"
	_island_panel.position = Vector2(1000, 150)
	_island_panel.changed.connect(_on_islands_changed)
	add_child(_island_panel)


func _add_tabs() -> void:
	_tab_buildings = UiStyle.secondary_button(&"BASE_TAB_BUILDINGS", Vector2(290, 120))
	_tab_buildings.name = "TabBuildings"
	_tab_buildings.position = Vector2(1000, 14)
	_tab_buildings.pressed.connect(_set_page.bind(0))
	add_child(_tab_buildings)
	_tab_islands = UiStyle.secondary_button(&"BASE_TAB_ISLANDS", Vector2(290, 120))
	_tab_islands.name = "TabIslands"
	_tab_islands.position = Vector2(1300, 14)
	_tab_islands.pressed.connect(_set_page.bind(1))
	add_child(_tab_islands)
	for tab: Button in [_tab_buildings, _tab_islands]:
		tab.add_theme_font_size_override(&"font_size", 38)


func _set_page(page_index: int) -> void:
	_page = page_index
	_place_camera()
	_buildings_card.visible = page_index == 0
	_island_panel.visible = page_index == 1
	_tab_buildings.modulate = Color.WHITE if page_index == 0 else Color(1, 1, 1, 0.65)
	_tab_islands.modulate = Color.WHITE if page_index == 1 else Color(1, 1, 1, 0.65)
	for node: Node in [_add_gold, _reset_gold, _reset_levels]:
		(node as Button).visible = page_index == 0


func _on_islands_changed() -> void:
	_rebuild_island()


func _add_test_buttons() -> void:
	# Nút thử nghiệm (đặt lại, thêm vàng) để xem đảo đổi hình qua từng cấp; xếp ngang giữa Quay lại và Chuẩn bị trận.
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "TestButtons"
	row.add_theme_constant_override(&"separation", 16)
	row.position = Vector2(430, 880)
	add_child(row)
	_reset_gold = UiStyle.secondary_button(&"BASE_RESET_GOLD", Vector2(270, 130))
	_reset_gold.pressed.connect(func() -> void: Profile.reset_gold(); refresh())
	_reset_levels = UiStyle.secondary_button(&"BASE_RESET_LEVELS", Vector2(270, 130))
	_reset_levels.pressed.connect(func() -> void: Profile.reset_levels(); refresh())
	_add_gold = UiStyle.secondary_button(&"BASE_ADD_GOLD", Vector2(270, 130))
	_add_gold.pressed.connect(func() -> void: Profile.add_gold(TEST_GOLD); refresh())
	for button: Button in [_reset_gold, _reset_levels, _add_gold]:
		button.add_theme_font_size_override(&"font_size", 34)
		row.add_child(button)


func _on_preview_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			_fingers[touch.index] = touch.position
		else:
			_fingers.erase(touch.index)
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if _fingers.size() >= 2 and _fingers.has(drag.index):
			var before: float = _finger_span()
			_fingers[drag.index] = drag.position
			var after: float = _finger_span()
			if before > 0.0 and after > 0.0:
				zoom_preview(after / before)
		elif _fingers.has(drag.index):
			_fingers[drag.index] = drag.position
	elif event is InputEventMouseButton:
		var button: InputEventMouseButton = event
		if button.button_index == MOUSE_BUTTON_LEFT:
			pass
		elif not button.pressed:
			pass
		elif button.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_preview(WHEEL_STEP)
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_preview(1.0 / WHEEL_STEP)
	elif event is InputEventMagnifyGesture:
		zoom_preview((event as InputEventMagnifyGesture).factor)
	elif event is InputEventMouseMotion and _fingers.size() < 2:
		var motion: InputEventMouseMotion = event
		if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			rotate_preview(-motion.relative.x * ROTATE_SPEED)
			tilt_preview(motion.relative.y * ROTATE_SPEED)


func _finger_span() -> float:
	var points: Array[Vector2] = _fingers.values()
	return points[0].distance_to(points[1]) if points.size() >= 2 else 0.0


func _place_camera() -> void:
	if _camera == null:
		return
	var center: Vector3 = _layout.fortress_center
	var page_scale: float = ISLAND_PAGE_DISTANCE if _page == 1 else 1.0
	var offset: Vector3 = (Vector3(0.0, sin(_pitch), cos(_pitch)) * CAMERA_RADIUS * _distance * page_scale).rotated(Vector3.UP, _yaw)
	_camera.look_at_from_position(center + offset, center + Vector3(0.0, 2.0, 0.0))


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
	_buildings_card = card
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
	container.gui_input.connect(_on_preview_input)
	_camera = Camera3D.new()
	_camera.fov = 35.0
	viewport.add_child(_camera)
	_place_camera()
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
	# Căn cứ chỉ có đảo chính và đảo phụ đã mua; nhà giàn thuộc về từng màn nên không hiện ở đây.
	_island.build(Profile.battle_layout(_layout).without_platforms())
