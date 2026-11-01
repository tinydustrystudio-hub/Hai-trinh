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
## Đảo vệ tinh người chơi sở hữu, mỗi phần tử là ô đang đặt (chỉ số trong MapLayout.satellite_slots) hoặc −1 nếu đang cất.
## Các đảo đầu tiên là đảo cấp sẵn của màn (không tốn phí dùng), các đảo sau là đảo mua thêm.
var islands: Array[int] = []
## Số đảo đã mua thêm.
var bought_islands: int = 0

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


## Số đảo tối đa được mua thêm ở màn này.
func max_bought_islands() -> int:
	return map().extra_satellites()


func island_total() -> int:
	return islands.size()


## Đảo đã đặt trên bản đồ.
func placed_count() -> int:
	var count: int = 0
	for slot: int in islands:
		if slot >= 0:
			count += 1
	return count


## Số đảo tối đa được đặt cùng lúc (GDD 5.4).
func max_placed() -> int:
	return map().satellite_max_count


func is_self_placed(island: int) -> bool:
	return island >= free_island_count()


## Đảo đang đặt ở ô slot, hoặc −1 nếu ô trống.
func island_at_slot(slot: int) -> int:
	return islands.find(slot)


## Đảo chưa đặt đầu tiên, hoặc −1.
func first_stored_island() -> int:
	return islands.find(-1)


func can_buy_island() -> bool:
	return bought_islands < max_bought_islands() and gold >= island_buy_cost()


func island_buy_cost() -> int:
	return economy_rules.island_buy_cost(bought_islands + 1)


## Mua một đảo (vật phẩm, có mãi); đảo mới nằm trong kho, chưa đặt.
func buy_island() -> bool:
	if not can_buy_island():
		return false
	set_gold(gold - island_buy_cost())
	bought_islands += 1
	islands.append(-1)
	islands_changed.emit()
	save()
	return true


## Phí dời một đảo đang đặt sang ô khác.
func island_move_cost() -> int:
	return economy_rules.island_move_cost(cheapest_tower_cost())


## Đặt đảo từ kho vào ô trống: miễn phí. Còn đảo đã đặt rồi mà dời thì tốn phí dời. Trả true nếu thành công.
func place_island(island: int, slot: int) -> bool:
	if island < 0 or island >= islands.size() or slot < 0 or slot >= map().slot_count():
		return false
	if island_at_slot(slot) >= 0:
		return false
	var moving: bool = islands[island] >= 0
	if not moving and placed_count() >= max_placed():
		return false
	if moving:
		var fee: int = island_move_cost()
		if gold < fee:
			return false
		set_gold(gold - fee)
	islands[island] = slot
	islands_changed.emit()
	save()
	return true


## Cất đảo về kho (miễn phí).
func store_island(island: int) -> bool:
	if island < 0 or island >= islands.size() or islands[island] < 0:
		return false
	islands[island] = -1
	islands_changed.emit()
	save()
	return true


## Phí dùng đảo tự đặt trong một trận: đảo tự đặt thứ nhất island_use_base, mỗi đảo sau cộng island_use_step.
## Chỉ tính các đảo trong danh sách chỉ số `used`.
func use_fee(used: Array[int]) -> int:
	var count: int = 0
	for island: int in used:
		if is_self_placed(island):
			count += 1
	return economy_rules.island_use_total(count)


## Các đảo dùng được ở trận tới: mọi đảo đã đặt, nhưng đảo tự đặt chỉ dùng khi Tiền Vàng trong ví trả nổi phí (xét theo thứ tự).
func battle_islands() -> Array[int]:
	var used: Array[int] = []
	var self_placed: int = 0
	var budget: int = gold
	for island: int in islands.size():
		if islands[island] < 0:
			continue
		if is_self_placed(island):
			var cost: int = economy_rules.island_use_cost(self_placed + 1)
			if cost > budget:
				continue
			budget -= cost
			self_placed += 1
		used.append(island)
	return used


## Trừ phí dùng đảo khỏi ví; trả số đã trừ.
func charge_use_fee(used: Array[int]) -> int:
	var fee: int = mini(use_fee(used), gold)
	if fee > 0:
		set_gold(gold - fee)
		save()
	return fee


## Bố cục của trận tới: bản đồ gốc với các đảo vệ tinh theo hồ sơ và công trình theo cấp.
func battle_layout(base: MapLayout, used: Array[int]) -> MapLayout:
	var centers: PackedVector3Array = PackedVector3Array()
	var utilities: Array[StringName] = []
	for island: int in used:
		centers.append(base.satellite_slots[islands[island]])
		utilities.append(base.satellite_utility(island))
	var layout: MapLayout = base.with_satellites(centers, utilities)
	layout.building_levels = building_levels.duplicate()
	return layout


## Đặt lại đảo như người chơi mới: bốn đảo cấp sẵn ở ô mặc định, chưa mua thêm.
func reset_islands() -> void:
	islands.clear()
	bought_islands = 0
	for i: int in free_island_count():
		islands.append(i)
	islands_changed.emit()


func to_dictionary() -> Dictionary:
	var levels: Dictionary = {}
	for id: StringName in building_levels:
		levels[String(id)] = building_levels[id]
	return {"gold": gold, "levels": levels, "islands": islands.duplicate(), "bought": bought_islands}


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
	_apply_islands(values)
	gold_changed.emit(gold)


func _apply_islands(values: Dictionary) -> void:
	reset_islands()
	var bought: Variant = values.get("bought")
	if bought is int:
		bought_islands = clampi(bought, 0, max_bought_islands())
		for i: int in bought_islands:
			islands.append(-1)
	var stored: Variant = values.get("islands")
	if stored is Array:
		var seen: Dictionary = {}
		for i: int in mini((stored as Array).size(), islands.size()):
			var slot: Variant = (stored as Array)[i]
			if slot is int and slot >= -1 and slot < map().slot_count() and (slot == -1 or not seen.has(slot)):
				islands[i] = slot
				if slot >= 0:
					seen[slot] = true
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
	reset_islands()
	gold_changed.emit(gold)
