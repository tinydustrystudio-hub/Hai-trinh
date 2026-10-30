extends GutTest
## Dữ liệu tháng 1 đọc đúng: 3 địch (kế hoạch mục 5.1), 5 đợt ở Bến Bắc, bản đồ, và các phép tính trên dữ liệu.

const SKIFF: EnemyData = preload("res://data/enemies/raider_skiff.tres")
const RAM: EnemyData = preload("res://data/enemies/ram_drone.tres")
const CRAB: EnemyData = preload("res://data/enemies/spiked_crab.tres")
const LAYOUT: MapLayout = preload("res://data/maps/north_dock_layout.tres")

const WAVES_PATH: String = "res://data/waves/north_dock_waves.tres"
const NORTH: int = 0
const EAST: int = 1
const WEST: int = 2

# Nạp lúc chạy, không dùng const preload: preload một .tres có mảng kiểu lớp tự định nghĩa
# làm trình phân tích của Godot 4.5 coi hai kiểu Wave là khác nhau.
var _waves: WaveData


func before_all() -> void:
	_waves = load(WAVES_PATH)


func _assert_enemy(data: EnemyData, id: StringName, health: float, speed: float, armor: float, steel: int, buoyancy: int) -> void:
	assert_eq(data.id, id)
	assert_eq(data.max_health, health, "%s máu" % id)
	assert_almost_eq(data.speed_cells, speed, 0.0001, "%s tốc độ" % id)
	assert_almost_eq(data.armor, armor, 0.0001, "%s giáp" % id)
	assert_eq(data.steel_reward, steel, "%s Thép" % id)
	assert_eq(data.buoyancy_damage, buoyancy, "%s Độ Nổi" % id)
	assert_eq(data.layer, EnemyData.Layer.SURFACE)
	assert_false(data.is_boss)


func test_raider_skiff() -> void:
	_assert_enemy(SKIFF, &"raider_skiff", 60.0, 0.8, 0.1, 5, 1)


func test_ram_drone() -> void:
	_assert_enemy(RAM, &"ram_drone", 60.0, 1.5, 0.1, 5, 3)


func test_spiked_crab() -> void:
	_assert_enemy(CRAB, &"spiked_crab", 800.0, 0.4, 0.5, 40, 2)


func test_enemy_names_are_translated() -> void:
	TranslationServer.set_locale("vi")
	assert_eq(tr(SKIFF.name_key), "Xuồng Cướp")
	assert_eq(tr(RAM.name_key), "Ca Nô Cảm Tử")
	assert_eq(tr(CRAB.name_key), "Cua Giáp Gai")


func test_speed_in_godot_units() -> void:
	assert_almost_eq(SKIFF.speed_units(), 3.2, 0.0001)


func test_map_start_values() -> void:
	assert_eq(LAYOUT.starting_steel, 200)
	assert_eq(LAYOUT.starting_buoyancy, 20)


func _count(wave: Wave, enemy: EnemyData) -> int:
	var total: int = 0
	for group: SpawnGroup in wave.groups:
		if group.enemy == enemy:
			total += group.count
	return total


func test_five_waves() -> void:
	assert_eq(_waves.wave_count(), 5)
	assert_gt(_waves.first_wave_delay, 0.0)


func test_wave_composition_matches_plan() -> void:
	var expected: Array[Array] = [
		[6, 0, 0, [NORTH]],
		[8, 3, 0, [NORTH, EAST]],
		[10, 0, 1, [NORTH, EAST, WEST]],
		[8, 6, 0, [EAST, WEST]],
		[12, 6, 2, [NORTH, EAST, WEST]],
	]
	for i: int in expected.size():
		var wave: Wave = _waves.waves[i]
		var row: Array = expected[i]
		assert_eq(_count(wave, SKIFF), row[0], "đợt %d: Xuồng Cướp" % (i + 1))
		assert_eq(_count(wave, RAM), row[1], "đợt %d: Ca Nô Cảm Tử" % (i + 1))
		assert_eq(_count(wave, CRAB), row[2], "đợt %d: Cua Giáp Gai" % (i + 1))
		assert_eq(Array(wave.lane_indices()), row[3], "đợt %d: luồng" % (i + 1))


func test_first_wave_spacing() -> void:
	var group: SpawnGroup = _waves.waves[0].groups[0]
	assert_almost_eq(group.interval, 1.5, 0.0001)


func test_groups_are_valid() -> void:
	for wave: Wave in _waves.waves:
		assert_gte(wave.rest_after, 0.0)
		for group: SpawnGroup in wave.groups:
			assert_not_null(group.enemy)
			assert_gt(group.count, 0)
			assert_gte(group.interval, 0.0)
			assert_gte(group.delay, 0.0)
			assert_between(group.lane_index, 0, LAYOUT.lane_count() - 1)


func test_total_enemies() -> void:
	assert_eq(_waves.total_enemy_count(), 6 + 11 + 11 + 14 + 20)


func test_group_last_spawn_time() -> void:
	var group: SpawnGroup = SpawnGroup.new()
	group.count = 6
	group.interval = 1.5
	group.delay = 2.0
	assert_almost_eq(group.last_spawn_time(), 9.5, 0.0001)
	group.count = 1
	assert_almost_eq(group.last_spawn_time(), 2.0, 0.0001)


func test_wave_duration_is_longest_group() -> void:
	var wave: Wave = Wave.new()
	var a: SpawnGroup = SpawnGroup.new()
	a.count = 3
	a.interval = 2.0
	var b: SpawnGroup = SpawnGroup.new()
	b.count = 2
	b.interval = 1.0
	b.delay = 5.0
	wave.groups = [a, b]
	assert_almost_eq(wave.duration(), 6.0, 0.0001)
	assert_eq(wave.enemy_count(), 5)


func test_tower_total_cost() -> void:
	var tower: TowerData = TowerData.new()
	for cost: int in [70, 60, 90]:
		var level: TowerLevel = TowerLevel.new()
		level.steel_cost = cost
		tower.levels.append(level)
	assert_eq(tower.max_level(), 3)
	assert_eq(tower.total_cost(1), 70)
	assert_eq(tower.total_cost(3), 220)
	assert_eq(tower.total_cost(9), 220)
	assert_eq(tower.level(2).steel_cost, 60)
	assert_true(tower.can_target(EnemyData.Layer.SURFACE))
	assert_false(tower.can_target(EnemyData.Layer.AIR))
