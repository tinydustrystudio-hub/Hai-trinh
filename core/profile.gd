extends Node
## Autoload Profile: hồ sơ người chơi lưu giữa các trận — ví Tiền Vàng chung và cấp các công trình của đảo chính
## (quyết định 31/10: một loại tiền cho cả trong trận lẫn ở căn cứ). Lưu xuống user://profile.cfg mỗi khi đổi;
## không ghi khi chạy không màn hình (test, CI), giống Settings.

signal gold_changed(value: int)
signal building_upgraded(id: StringName, level: int)

const SAVE_PATH: String = "user://profile.cfg"
const BUILDING_PATHS: Array[String] = [
	"res://data/buildings/wave_shield.tres",
	"res://data/buildings/repair_works.tres",
	"res://data/buildings/tidal_power.tres",
	"res://data/buildings/shipyard.tres",
]
## Tiền Vàng của người chơi mới (số tạm để thử nâng cấp ngay; chỉnh sau khi chơi thử).
const NEW_PLAYER_GOLD: int = 500

@export var economy_rules: EconomyData = preload("res://data/economy.tres")

var gold: int = NEW_PLAYER_GOLD
var building_levels: Dictionary[StringName, int] = {}
var persist: bool = true

var _buildings: Array[BuildingData] = []


func _ready() -> void:
	persist = DisplayServer.get_name() != "headless"
	if persist:
		load_saved()


func buildings() -> Array[BuildingData]:
	if _buildings.is_empty():
		for path: String in BUILDING_PATHS:
			_buildings.append(load(path) as BuildingData)
	return _buildings


func building(id: StringName) -> BuildingData:
	for data: BuildingData in buildings():
		if data.id == id:
			return data
	return null


func level_of(id: StringName) -> int:
	return clampi(building_levels.get(id, 1), 1, BuildingData.MAX_LEVEL)


func is_max_level(id: StringName) -> bool:
	return level_of(id) >= BuildingData.MAX_LEVEL


## Giá lên cấp kế tiếp, 0 nếu đã tối đa hoặc không có công trình.
func upgrade_cost(id: StringName) -> int:
	var data: BuildingData = building(id)
	if data == null or is_max_level(id):
		return 0
	return economy_rules.building_upgrade_cost(level_of(id) + 1, data.upgrade_multiplier)


func can_upgrade(id: StringName) -> bool:
	return building(id) != null and not is_max_level(id) and gold >= upgrade_cost(id)


## Nâng một cấp, trừ Tiền Vàng; trả true nếu đã nâng.
func upgrade(id: StringName) -> bool:
	if not can_upgrade(id):
		return false
	var cost: int = upgrade_cost(id)
	set_gold(gold - cost)
	building_levels[id] = level_of(id) + 1
	building_upgraded.emit(id, building_levels[id])
	save()
	return true


func add_gold(amount: int) -> void:
	if amount > 0:
		set_gold(gold + amount)
		save()


func set_gold(value: int) -> void:
	gold = maxi(value, 0)
	gold_changed.emit(gold)


## Tiền Vàng cộng vào ví sau một trận: số kiếm được trong trận, cộng thưởng thắng nếu thắng.
func payout_for(earned: int, won: bool) -> int:
	return maxi(earned, 0) + (economy_rules.victory_bonus if won else 0)


func settle_battle(earned: int, won: bool) -> int:
	var amount: int = payout_for(earned, won)
	add_gold(amount)
	return amount


func to_dictionary() -> Dictionary:
	var levels: Dictionary = {}
	for id: StringName in building_levels:
		levels[String(id)] = building_levels[id]
	return {"gold": gold, "levels": levels}


func apply_dictionary(values: Dictionary) -> void:
	var stored: Variant = values.get("gold")
	if stored is int:
		gold = maxi(stored, 0)
	building_levels.clear()
	var levels: Variant = values.get("levels")
	if levels is Dictionary:
		for key: Variant in (levels as Dictionary):
			var level: Variant = (levels as Dictionary)[key]
			if level is int and building(StringName(str(key))) != null:
				building_levels[StringName(str(key))] = clampi(level, 1, BuildingData.MAX_LEVEL)
	gold_changed.emit(gold)


func save(path: String = SAVE_PATH, force: bool = false) -> bool:
	if not persist and not force:
		return false
	var config: ConfigFile = ConfigFile.new()
	var values: Dictionary = to_dictionary()
	for key: String in values:
		config.set_value("profile", key, values[key])
	return config.save(path) == OK


func load_saved(path: String = SAVE_PATH) -> bool:
	var config: ConfigFile = ConfigFile.new()
	if config.load(path) != OK:
		return false
	var values: Dictionary = {}
	for key: String in config.get_section_keys("profile"):
		values[key] = config.get_value("profile", key)
	apply_dictionary(values)
	return true


## Ghi đè bằng hồ sơ mới (cho test).
func reset_to_new() -> void:
	gold = NEW_PLAYER_GOLD
	building_levels.clear()
	gold_changed.emit(gold)
