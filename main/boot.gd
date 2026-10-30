extends Node
## Màn khởi động: hiện tên game trong lúc nạp cài đặt, rồi chuyển sang trận.
## Tháng 1 vào thẳng trận, chưa có menu.

const BATTLE_SCENE: String = "res://battle/battle.tscn"

@onready var _title: Label = $Title


func _ready() -> void:
	_title.text = tr(&"GAME_TITLE")
	# Chỉ chuyển cảnh khi boot là cảnh chính; khi test nạp boot làm nút con thì đứng yên.
	if get_tree().current_scene == self:
		_go_to_battle.call_deferred()


func _go_to_battle() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE)
