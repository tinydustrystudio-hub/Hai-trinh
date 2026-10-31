extends Node
## Autoload Settings: cài đặt người chơi dùng chung giữa các màn (chất lượng nước, tốc độ, âm lượng),
## và cờ khởi chạy cho bản thử (bảng debug, cảnh thử 60 địch).
## Tháng 1 chưa lưu xuống đĩa; các bước sau thêm khi có màn Cài đặt.

signal water_quality_changed(quality: Ocean.Quality)
## Bật tắt âm thanh hoặc nhạc nền.
signal audio_changed

var water_quality: Ocean.Quality = Ocean.Quality.HIGH:
	set(value):
		if water_quality == value:
			return
		water_quality = value
		water_quality_changed.emit(value)
## Tự hạ chất lượng nước khi khung hình thấp kéo dài.
var auto_lower_quality: bool = true
## Cài đặt nhanh trong màn Tạm dừng (GDD mục 7.11). Tắt âm thanh thì tắt cả nhạc nền.
var sound_enabled: bool = true:
	set(value):
		if sound_enabled == value:
			return
		sound_enabled = value
		audio_changed.emit()
## Nhạc nền tạm (góp ý 3 của đạo diễn), bật tắt riêng.
var music_enabled: bool = true:
	set(value):
		if music_enabled == value:
			return
		music_enabled = value
		audio_changed.emit()
## Rung khi địch đâm vào đảo chính, khi nổ MEGA và khi tàu trùm nổ (góp ý 3).
var vibration_enabled: bool = true

var _watch: FrameRateWatch = FrameRateWatch.new()
var _last_usec: int = 0
var _web_query: String = ""


func _ready() -> void:
	if OS.has_feature("web"):
		var query: Variant = JavaScriptBridge.eval("window.location.search", true)
		_web_query = str(query) if query != null else ""
	# Máy không có màn hình (CI, test) thì khung/giây vô nghĩa; ?hq giữ chất lượng cao (chụp ảnh, so sánh).
	if DisplayServer.get_name() == "headless" or launch_flag("hq"):
		auto_lower_quality = false


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	var real_delta: float = 0.0 if _last_usec == 0 else float(now - _last_usec) / 1_000_000.0
	_last_usec = now
	if not auto_lower_quality or water_quality == Ocean.Quality.LOW:
		return
	if _watch.update(Engine.get_frames_per_second(), real_delta):
		print("Settings: khung hình dưới 30 liên tục 5 giây, hạ chất lượng nước xuống thấp")
		water_quality = Ocean.Quality.LOW


## Cờ khởi chạy: "--<name>" trong tham số dòng lệnh (sau "--"), hoặc "<name>" trong query của trang web.
func launch_flag(flag: String) -> bool:
	if OS.get_cmdline_user_args().has("--" + flag):
		return true
	return has_query_flag(_web_query, flag)


## Bảng debug có trong bản debug, hoặc bản web mở với ?debug.
func debug_tools_enabled() -> bool:
	return OS.is_debug_build() or launch_flag("debug") or launch_flag("stress")


## Giá trị của tham số "<name>=giá_trị" trong tham số dòng lệnh ("--name=giá_trị") hoặc query trang web; rỗng nếu không có.
func launch_value(name: String) -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--" + name + "="):
			return argument.substr(name.length() + 3)
	return query_value(_web_query, name)


static func query_value(query: String, name: String) -> String:
	var trimmed: String = query.trim_prefix("?")
	for part: String in trimmed.split("&", false):
		if part.begins_with(name + "="):
			return part.substr(name.length() + 1)
	return ""


static func has_query_flag(query: String, flag: String) -> bool:
	var trimmed: String = query.trim_prefix("?")
	if trimmed.is_empty():
		return false
	for part: String in trimmed.split("&", false):
		if part == flag or part.begins_with(flag + "="):
			return true
	return false
