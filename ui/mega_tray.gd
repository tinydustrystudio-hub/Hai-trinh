class_name MegaTray
extends Control
## Khay MEGA ở góc dưới bên phải (GDD mục 7.10): tối đa 4 nút cho các lô cốt đã đầy thanh Quá tải,
## xếp theo thứ tự đầy (lô cốt đầy trước ở ngoài cùng bên phải). Chạm nút để kích MEGA.

signal mega_requested(tower: Tower)

const MAX_SLOTS: int = 4
const BUTTON_SIZE: float = 140.0
const GAP: float = 16.0

## Lô cốt đang chờ kích, theo thứ tự đầy thanh.
var queue: Array[Tower] = []

var _buttons: Array[Button] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	for i: int in MAX_SLOTS:
		var button: Button = UiStyle.primary_button(&"", Vector2(BUTTON_SIZE, BUTTON_SIZE))
		button.name = "Mega%d" % i
		button.add_theme_font_size_override(&"font_size", 30)
		button.pressed.connect(_on_pressed.bind(i))
		button.visible = false
		add_child(button)
		_buttons.append(button)
	resized.connect(_layout)
	_layout()


## Lô cốt vừa đầy thanh: thêm vào khay (bỏ qua nếu khay đầy hoặc đã có).
func add(tower: Tower) -> void:
	if queue.has(tower):
		return
	queue.append(tower)
	_refresh()


## Lô cốt đã kích hoặc bị bán: bỏ khỏi khay.
func remove(tower: Tower) -> void:
	queue.erase(tower)
	_refresh()


func clear() -> void:
	queue.clear()
	_refresh()


func buttons() -> Array[Button]:
	return _buttons


func visible_count() -> int:
	return mini(queue.size(), MAX_SLOTS)


func _refresh() -> void:
	for i: int in MAX_SLOTS:
		var button: Button = _buttons[i]
		button.visible = i < queue.size()
		if button.visible:
			button.text = "MEGA\n%s" % tr(queue[i].data.name_key)
	_layout()


func _layout() -> void:
	var screen: Vector2 = size if size != Vector2.ZERO else get_viewport_rect().size
	for i: int in _buttons.size():
		var x: float = screen.x - UiStyle.MARGIN * 2 - BUTTON_SIZE * float(i + 1) - GAP * float(i)
		_buttons[i].size = Vector2(BUTTON_SIZE, BUTTON_SIZE)
		_buttons[i].position = Vector2(x, screen.y - UiStyle.MARGIN * 2 - BUTTON_SIZE)


func _on_pressed(index: int) -> void:
	if index < queue.size():
		mega_requested.emit(queue[index])
