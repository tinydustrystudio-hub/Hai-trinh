class_name UpgradeRing
extends Control
## Vòng nâng cấp mở quanh lô cốt vừa chạm (GDD mục 7.10): nút Nâng cấp kèm giá (ở cấp 4 là Chọn nhánh,
## ở cấp 5 là Cấp tối đa) và nút Bán kèm số Thép hoàn lại. Thiếu Thép thì nút nâng xám. Nút từ 120 px.

signal upgrade_requested
signal branch_requested
signal sell_requested

var tower: Tower = null

var _upgrade: Button
var _sell: Button
var _level: Label
var _steel: int = 0
var _refund: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_upgrade = UiStyle.primary_button(&"", Vector2(BuildRing.BUTTON_SIZE, BuildRing.BUTTON_SIZE))
	_upgrade.name = "Upgrade"
	_upgrade.add_theme_font_size_override(&"font_size", 28)
	_upgrade.pressed.connect(_on_upgrade_pressed)
	add_child(_upgrade)
	_sell = UiStyle.primary_button(&"", Vector2(BuildRing.BUTTON_SIZE, BuildRing.BUTTON_SIZE))
	_sell.name = "Sell"
	_sell.add_theme_font_size_override(&"font_size", 28)
	_sell.pressed.connect(sell_requested.emit)
	add_child(_sell)
	_level = UiStyle.label(30)
	_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_level)
	visible = false


## Mở vòng quanh at cho lô cốt chosen; refund là số Thép hoàn lại nếu bán.
func open(at: Vector2, chosen: Tower, steel: int, refund: int) -> void:
	tower = chosen
	_steel = steel
	_refund = refund
	var screen: Vector2 = get_viewport_rect().size
	var size: Vector2 = Vector2(BuildRing.BUTTON_SIZE, BuildRing.BUTTON_SIZE)
	_upgrade.size = size
	_sell.size = size
	_upgrade.position = BuildRing.button_center(0, 2, at, screen) - size * 0.5
	_sell.position = BuildRing.button_center(1, 2, at, screen) - size * 0.5
	_level.size = Vector2(240, 40)
	_level.position = Vector2(clampf(at.x - 120.0, 0.0, screen.x - 240.0), clampf(at.y + 40.0, 0.0, screen.y - 40.0))
	_refresh()
	visible = true


func close() -> void:
	visible = false
	tower = null


func is_open() -> bool:
	return visible


func set_steel(value: int) -> void:
	_steel = value
	if visible:
		_refresh()


func upgrade_button() -> Button:
	return _upgrade


func sell_button() -> Button:
	return _sell


func _refresh() -> void:
	if tower == null:
		return
	_level.text = tr(&"TOWER_LEVEL") % mini(tower.level, tower.data.max_level() + 1)
	_sell.text = "%s\n+%d" % [tr(&"SELL"), _refund]
	if tower.is_max_level():
		_upgrade.text = tr(&"UPGRADE_MAX")
		_set_enabled(_upgrade, false)
	elif tower.needs_branch():
		var cheapest: int = tower.data.branches[0].steel_cost
		for option: TowerBranch in tower.data.branches:
			cheapest = mini(cheapest, option.steel_cost)
		_upgrade.text = "%s\n%d" % [tr(&"UPGRADE_BRANCH"), cheapest]
		_set_enabled(_upgrade, cheapest <= _steel)
	else:
		var cost: int = tower.next_level_cost()
		_upgrade.text = "%s\n%d" % [tr(&"UPGRADE_LEVEL"), cost]
		_set_enabled(_upgrade, cost <= _steel)


func _set_enabled(button: Button, enabled: bool) -> void:
	button.disabled = not enabled


func _on_upgrade_pressed() -> void:
	if tower == null or _upgrade.disabled:
		return
	if tower.needs_branch():
		branch_requested.emit()
	else:
		upgrade_requested.emit()

