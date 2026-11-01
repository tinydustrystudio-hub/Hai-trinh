extends Node
## Điều phối luồng màn hình (P2 kế hoạch hoàn thiện): Tiêu đề → Chuẩn bị trận → Trận → (Kết quả) → Về menu,
## kèm Cài đặt từ màn Tiêu đề. Mỗi lần chỉ có một màn là con của Boot. `?stress` mở thẳng cảnh thử 60 địch;
## `?play` (hoặc `--play`) vào thẳng trận, bỏ qua menu (cho thử nhanh).

const BATTLE_SCENE: PackedScene = preload("res://battle/battle.tscn")
## Mở thẳng cảnh thử 60 địch: tham số "-- --stress" hoặc trang web với ?stress.
const STRESS_SCENE: String = "res://test_scenes/stress_test.tscn"
const LAYOUT_PATH: String = "res://data/maps/north_dock_layout.tres"
const WAVES_PATH: String = "res://data/waves/north_dock_waves.tres"
const TOWER_PATHS: Array[String] = [
	"res://data/towers/machine_gun.tres",
	"res://data/towers/glue_sprayer.tres",
	"res://data/towers/light_beam.tres",
]

## Màn đang hiện (Control hoặc BattleController).
var current: Node

@onready var _splash: Label = $Title


func _ready() -> void:
	_splash.text = tr(&"GAME_TITLE")
	# Chỉ chuyển cảnh khi boot là cảnh chính; khi test nạp boot làm nút con thì đứng yên.
	if get_tree().current_scene == self:
		_start.call_deferred()


func _start() -> void:
	if Settings.launch_flag("stress"):
		get_tree().change_scene_to_file(STRESS_SCENE)
	elif Settings.launch_flag("play"):
		show_battle()
	else:
		show_title()


func show_title() -> TitleScreen:
	var screen: TitleScreen = TitleScreen.new()
	screen.play_requested.connect(show_prep)
	screen.settings_requested.connect(show_settings)
	_swap(screen)
	return screen


func show_settings() -> SettingsScreen:
	var screen: SettingsScreen = SettingsScreen.new()
	screen.back_requested.connect(show_title)
	_swap(screen)
	return screen


func show_prep() -> PrepScreen:
	var screen: PrepScreen = PrepScreen.new()
	var towers: Array[TowerData] = []
	for path: String in TOWER_PATHS:
		towers.append(load(path))
	screen.setup(load(LAYOUT_PATH), load(WAVES_PATH), towers)
	screen.start_requested.connect(show_battle)
	screen.back_requested.connect(show_title)
	_swap(screen)
	return screen


func show_battle() -> BattleController:
	var battle: BattleController = BATTLE_SCENE.instantiate()
	battle.menu_requested.connect(return_to_menu)
	_swap(battle)
	if not Settings.tutorial_done:
		battle.enable_tutorial()
	return battle


## Từ trận (kết quả hoặc tạm dừng) về màn Tiêu đề.
func return_to_menu() -> void:
	# Trả thời gian về bình thường trước khi rời trận (đang tạm dừng hay ×2).
	Engine.time_scale = 1.0
	show_title()


func _swap(next: Node) -> void:
	if is_instance_valid(current):
		current.queue_free()
	_splash.visible = false
	current = next
	add_child(next)
