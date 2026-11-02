extends Node
## Autoload Profile: hồ sơ người chơi lưu giữa các trận — ví Tiền Vàng chung và cấp các công trình của đảo chính
## (quyết định 31/10: một loại tiền cho cả trong trận lẫn ở căn cứ). Lưu xuống user://profile.cfg mỗi khi đổi;
## không ghi khi chạy không màn hình (test, CI), giống Settings.

signal gold_changed(value: int)
signal building_upgraded(id: StringName, level: int)
## Đảo vệ tinh được mua, đặt, dời hoặc gỡ.
signal islands_changed

const SAVE_PATH: String = "user://profile.cfg"
const BUILDING_PATHS: Array[String] = [
	"res://data/buildings/wave_shield.tres",
	"res://data/buildings/repair_works.tres",
	"res://data/buildings/tidal_power.tres",
	"res://data/buildings/shipyard.tres",
]
const MAP_PATH: String = "res://data/maps/north_dock_layout.tres"
const TOWER_PATHS: Array[String] = [
	"res://data/towers/machine_gun.tres",
	"res://data/towers/glue_sprayer.tres",
	"res://data/towers/light_beam.tres",
]
## Tiền Vàng của người chơi mới (số tạm để thử nâng cấp ngay; chỉnh sau khi chơi thử).
const NEW_PLAYER_GOLD: int = 500

@export var economy_rules: EconomyData = preload("res://data/economy.tres")

var gold: int = NEW_PLAYER_GOLD
var building_levels: Dictionary[StringName, int] = {}
var persist: bool = true
## Số đảo vệ tinh đã mua thêm. Đảo mua rồi có mãi, nằm cạnh đảo chính; vào trận mới kéo ra ô chọn (tốn phí kéo).
var bought_islands: int = 0
## Độ khó đang chơi (Difficulty.Level); quyết định còn mua thêm được bao nhiêu đảo vệ tinh.
var difficulty: int = Difficulty.Level.NORMAL

var _buildings: Array[BuildingData] = []
var _map: MapLayout
var _cheapest_tower: int = 0


func _ready() -> void:
	persist = DisplayServer.get_name() != "headless"
	reset_islands()
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


## Bố cục bản đồ gốc (dùng để biết ô đặt đảo, số đảo cấp sẵn).
func map() -> MapLayout:
	if _map == null:
		_map = load(MAP_PATH) as MapLayout
	return _map


## Giá lô cốt rẻ nhất ở cấp 1.
func cheapest_tower_cost() -> int:
	if _cheapest_tower == 0:
		_cheapest_tower = 1 << 30
		for path: String in TOWER_PATHS:
			_cheapest_tower = mini(_cheapest_tower, (load(path) as TowerData).level(1).steel_cost)
	return _cheapest_tower


func free_island_count() -> int:
	return map().free_satellites()


## Số đảo phụ mua được tối đa (mua có mãi, không phụ thuộc độ khó): 12 ở màn Bến Bắc.
func max_bought_islands() -> int:
	return maxi(map().satellite_max_count - map().free_satellites(), 0)


## Số đảo mua thêm đặt được trong màn ở độ khó đang chơi: màn dễ cho đặt nhiều đảo, màn khó đặt ít hơn
## (giới hạn tổng nhà giàn + đảo phụ, MapLayout.outpost_limits). Đảo mua nhiều hơn mức này vẫn giữ nguyên, chỉ không đặt vào màn.
func usable_bought_islands() -> int:
	return mini(bought_islands, map().extra_satellites(difficulty))


## Tổng số đảo vệ tinh dùng được: đảo cấp sẵn và đảo đã mua.
func island_total() -> int:
	return free_island_count() + usable_bought_islands()


## Tổng nhà giàn và đảo vệ tinh của trận ở độ khó đang chơi.
func outpost_total() -> int:
	return map().platform_centers.size() + island_total()


func set_difficulty(level: int) -> void:
	difficulty = clampi(level, 0, Difficulty.IDS.size() - 1)
	islands_changed.emit()
	save()


func can_buy_island() -> bool:
	return bought_islands < max_bought_islands() and gold >= island_buy_cost()


func island_buy_cost() -> int:
	return economy_rules.island_buy_cost(bought_islands + 1)


## Mua một đảo (vật phẩm, có mãi); đảo mới nằm ở chỗ đậu cạnh đảo chính.
func buy_island() -> bool:
	if not can_buy_island():
		return false
	set_gold(gold - island_buy_cost())
	bought_islands += 1
	islands_changed.emit()
	save()
	return true


## Phí kéo một đảo ra ô trong trận (và dời tiếp): bằng ½ giá lô cốt rẻ nhất.
func island_move_cost() -> int:
	return economy_rules.island_move_cost(cheapest_tower_cost())


## Phí kéo một đảo đang mang lô cốt: một khoản gộp (60 → 180), không cộng thêm phí dời lô cốt.
func island_loaded_move_cost() -> int:
	return economy_rules.island_loaded_move_cost(cheapest_tower_cost())


## Phí dời một lô cốt sang bệ khác: bằng giá lô cốt rẻ nhất.
func tower_move_cost() -> int:
	return economy_rules.tower_move_cost(cheapest_tower_cost())


## Bố cục của trận: đảo cấp sẵn ở ô mặc định, đảo mua thêm đậu ở chỗ đậu cạnh đảo chính, công trình theo cấp.
func battle_layout(base: MapLayout) -> MapLayout:
	var centers: PackedVector3Array = PackedVector3Array()
	var utilities: Array[StringName] = []
	for i: int in free_island_count():
		centers.append(base.satellite_centers[i])
		utilities.append(base.satellite_utility(i))
	for i: int in mini(usable_bought_islands(), base.satellite_docks.size()):
		centers.append(base.satellite_docks[i])
		utilities.append(base.satellite_utility(free_island_count() + i))
	var layout: MapLayout = base.with_satellites(centers, utilities)
	layout.building_levels = building_levels.duplicate()
	return layout


## Đặt lại số đảo đã mua về 0 (không hoàn vàng).
func reset_islands() -> void:
	bought_islands = 0
	islands_changed.emit()


func to_dictionary() -> Dictionary:
	var levels: Dictionary = {}
	for id: StringName in building_levels:
		levels[String(id)] = building_levels[id]
	return {"gold": gold, "levels": levels, "bought": bought_islands, "difficulty": String(Difficulty.id_of(difficulty))}


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
	var stored_difficulty: Variant = values.get("difficulty")
	difficulty = Difficulty.from_id(StringName(str(stored_difficulty))) if stored_difficulty is String else Difficulty.Level.NORMAL
	_apply_islands(values)
	gold_changed.emit(gold)


func _apply_islands(values: Dictionary) -> void:
	bought_islands = 0
	var bought: Variant = values.get("bought")
	if bought is int:
		bought_islands = clampi(bought, 0, mini(max_bought_islands(), map().satellite_docks.size()))
	islands_changed.emit()


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


## Đặt lại Tiền Vàng về mức người chơi mới (nút thử nghiệm ở màn Căn cứ).
func reset_gold() -> void:
	set_gold(NEW_PLAYER_GOLD)
	save()


## Đặt lại cấp mọi công trình về 1, giữ nguyên Tiền Vàng.
func reset_levels() -> void:
	building_levels.clear()
	for data: BuildingData in buildings():
		building_upgraded.emit(data.id, 1)
	save()


## Ghi đè bằng hồ sơ mới (cho test).
func reset_to_new() -> void:
	gold = NEW_PLAYER_GOLD
	building_levels.clear()
	difficulty = Difficulty.Level.NORMAL
	reset_islands()
	gold_changed.emit(gold)
