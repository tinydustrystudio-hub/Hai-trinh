extends Node
## Autoload Settings: cài đặt người chơi dùng chung giữa các màn (chất lượng nước, tốc độ, âm lượng),
## và cờ khởi chạy cho bản thử (bảng debug, cảnh thử 60 địch).
## Cài đặt người chơi lưu xuống máy (user://settings.cfg) mỗi khi đổi; không lưu khi chạy không màn hình (test, CI).

signal water_quality_changed(quality: Ocean.Quality)
## Bật tắt âm thanh hoặc nhạc nền.
signal audio_changed

const DEFAULT_LOCALE: String = "vi"
const LANGUAGES: Array[String] = ["vi", "en"]
const SAVE_PATH: String = "user://settings.cfg"

var water_quality: Ocean.Quality = Ocean.Quality.HIGH:
	set(value):
		if water_quality == value:
			return
		water_quality = value
		water_quality_changed.emit(value)
		save()
## Tự hạ chất lượng nước khi khung hình thấp kéo dài.
var auto_lower_quality: bool = true
## Cài đặt nhanh trong màn Tạm dừng (GDD mục 7.11). Tắt âm thanh thì tắt cả nhạc nền.
var sound_enabled: bool = true:
	set(value):
		if sound_enabled == value:
			return
		sound_enabled = value
		audio_changed.emit()
		save()
## Nhạc nền tạm (góp ý 3 của đạo diễn), bật tắt riêng.
var music_enabled: bool = true:
	set(value):
		if music_enabled == value:
			return
		music_enabled = value
		audio_changed.emit()
		save()
## Rung khi địch đâm vào đảo chính, khi nổ MEGA và khi tàu trùm nổ (góp ý 3).
var vibration_enabled: bool = true:
	set(value):
		vibration_enabled = value
		save()
## Ngôn ngữ giao diện ("vi" hoặc "en").
var language: String = DEFAULT_LOCALE:
	set(value):
		language = value if value in LANGUAGES else DEFAULT_LOCALE
		TranslationServer.set_locale(language)
		save()
## Đã xem xong hướng dẫn vài bước đầu chưa.
var tutorial_done: bool = false:
	set(value):
		tutorial_done = value
		save()
## Có ghi xuống máy không (tắt khi chạy không màn hình và khi nạp cài đặt).
var persist: bool = true

var _watch: FrameRateWatch = FrameRateWatch.new()
var _last_usec: int = 0
var _web_query: String = ""


func _ready() -> void:
	if OS.has_feature("web"):
		var query: Variant = JavaScriptBridge.eval("window.location.search", true)
		_web_query = str(query) if query != null else ""
	# Không ghi xuống máy khi chạy không màn hình (test, CI).
	persist = DisplayServer.get_name() != "headless"
	if persist:
		load_saved()
	# Mặc định tiếng Việt trên mọi nền tảng (web theo ngôn ngữ trình duyệt thường ra tiếng Anh, điện thoại ra tiếng Việt
	# làm bản chơi khác nhau); ?lang=en hoặc --lang=en ghi đè; không có thì dùng ngôn ngữ đã chọn trong Cài đặt.
	var wanted: String = launch_value("lang")
	TranslationServer.set_locale(wanted if wanted in LANGUAGES else language)
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


## Cài đặt dưới dạng từ điển để lưu.
func to_dictionary() -> Dictionary:
	return {
		"sound": sound_enabled,
		"music": music_enabled,
		"vibration": vibration_enabled,
		"water_quality": int(water_quality),
		"language": language,
		"tutorial_done": tutorial_done,
	}


## Nạp từ từ điển (giá trị thiếu hoặc sai kiểu thì giữ nguyên); không ghi lại xuống máy trong lúc nạp.
func apply_dictionary(values: Dictionary) -> void:
	var was_persisting: bool = persist
	persist = false
	sound_enabled = _as_bool(values.get("sound"), sound_enabled)
	music_enabled = _as_bool(values.get("music"), music_enabled)
	vibration_enabled = _as_bool(values.get("vibration"), vibration_enabled)
	var quality: Variant = values.get("water_quality")
	if quality is int and quality in [Ocean.Quality.LOW, Ocean.Quality.HIGH]:
		water_quality = quality as Ocean.Quality
	language = str(values.get("language", language))
	tutorial_done = _as_bool(values.get("tutorial_done"), tutorial_done)
	persist = was_persisting


static func _as_bool(value: Variant, fallback: bool) -> bool:
	return value if value is bool else fallback


## Ghi cài đặt xuống path; trả true nếu ghi được. Không ghi khi persist = false, trừ khi force (cho test ghi file tạm).
func save(path: String = SAVE_PATH, force: bool = false) -> bool:
	if not persist and not force:
		return false
	var config: ConfigFile = ConfigFile.new()
	var values: Dictionary = to_dictionary()
	for key: String in values:
		config.set_value("settings", key, values[key])
	return config.save(path) == OK


## Nạp cài đặt từ path; trả true nếu có file.
func load_saved(path: String = SAVE_PATH) -> bool:
	var config: ConfigFile = ConfigFile.new()
	if config.load(path) != OK:
		return false
	var values: Dictionary = {}
	for key: String in config.get_section_keys("settings"):
		values[key] = config.get_value("settings", key)
	apply_dictionary(values)
	return true


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
