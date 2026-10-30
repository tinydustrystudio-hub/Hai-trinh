extends Node
## Màn khởi động. Bước 1 chỉ hiện tên game; các bước sau nạp cài đặt rồi chuyển sang trận.

@onready var _title: Label = $Title


func _ready() -> void:
	_title.text = tr(&"GAME_TITLE")
