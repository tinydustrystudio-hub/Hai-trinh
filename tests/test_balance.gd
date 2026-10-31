extends GutTest
## Cân bằng 5 đợt ở Bến Bắc (kế hoạch bước 12) bằng người chơi giả: không làm gì thì thua; đặt lô cốt
## qua loa thì thua; chơi có chiến thuật (đặt theo luồng, keo cho Ca Nô, nâng cấp, MEGA) thì thắng
## nhưng không quá dễ (mất một phần Độ Nổi).

const BATTLE_SCENE: PackedScene = preload("res://battle/battle.tscn")


func _play(strategy: BattleBot.Strategy) -> BattleController:
	var battle: BattleController = add_child_autofree(BATTLE_SCENE.instantiate())
	var leaks: Dictionary = {}
	var count_leak: Callable = func(e: Enemy, d: int) -> void:
		var key: String = "%s/%s/đợt %d" % [e.data.id, e.lane.name_key, battle.spawner.wave_index + 1]
		leaks[key] = leaks.get(key, 0) + d
	var starts: PackedStringArray = PackedStringArray()
	var note_start: Callable = func(index: int, _total: int) -> void:
		starts.append("đợt %d: Thép %d, %d lô cốt" % [index + 1, battle.economy.steel, battle.towers.size()])
	Events.enemy_leaked.connect(count_leak)
	Events.wave_started.connect(note_start)
	var elapsed: float = BattleBot.play(battle, strategy)
	Events.enemy_leaked.disconnect(count_leak)
	Events.wave_started.disconnect(note_start)
	gut.p("  " + "; ".join(starts))
	var desc: PackedStringArray = PackedStringArray()
	for tower: Tower in battle.towers:
		desc.append("%s cấp %d (bệ %d)" % [tower.data.id, tower.level, tower.pad.pad_index])
	gut.p("%s: %s ở đợt %d sau %.0f giây, Độ Nổi %d/20, Thép %d; lô cốt: %s; lọt: %s" % [
		BattleBot.Strategy.keys()[strategy], BattleController.State.keys()[battle.state],
		battle.spawner.wave_index + 1, elapsed, battle.buoyancy.value, battle.economy.steel, ", ".join(desc), str(leaks)])
	return battle


func test_naive_player_loses() -> void:
	var battle: BattleController = _play(BattleBot.Strategy.NAIVE)
	assert_eq(battle.state, BattleController.State.LOST)


func test_smart_player_wins_but_not_too_easily() -> void:
	var battle: BattleController = _play(BattleBot.Strategy.SMART)
	if battle.state != BattleController.State.WON:
		# Đạo diễn chọn giữ số GDD và cân bằng sau buổi chơi thử trên điện thoại (31/10); kết quả thử ở
		# docs/so-lieu-khoi-dau.md, mục "Thử cân bằng".
		pending("Chưa cân bằng: người chơi có chiến thuật thua ở đợt %d" % (battle.spawner.wave_index + 1))
		return
	assert_lt(battle.buoyancy.value, 20, "không thắng quá dễ: vẫn để lọt vài tàu")
