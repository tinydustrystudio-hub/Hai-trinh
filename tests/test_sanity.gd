extends GutTest
## Test mẫu: kiểm tra GUT chạy được, bảng dịch đã nạp và màn khởi động hiện đúng tên game.

const BOOT_SCENE: PackedScene = preload("res://main/boot.tscn")


func test_gut_runs() -> void:
	assert_eq(1 + 1, 2)


func test_game_title_is_translated() -> void:
	TranslationServer.set_locale("vi")
	assert_eq(tr(&"GAME_TITLE"), "Hải Trình")


func test_boot_shows_game_title() -> void:
	TranslationServer.set_locale("vi")
	var boot: Node = add_child_autofree(BOOT_SCENE.instantiate())
	var title: Label = boot.get_node("Title")
	assert_eq(title.text, "Hải Trình")
