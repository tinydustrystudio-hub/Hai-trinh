extends Node3D
## Cảnh thử hiệu năng: trận Bến Bắc luôn giữ đủ 60 địch trên biển; bảng debug luôn mở
## và ghi số đo ra console mỗi vài giây (để đọc từ trình duyệt hoặc logcat).

@onready var battle: BattleController = $Battle


func _ready() -> void:
	battle.enter_stress_mode()
	var overlay: DebugOverlay = battle.get_node_or_null("DebugOverlay")
	if overlay != null:
		overlay.expanded = true
		overlay.log_to_console = true
