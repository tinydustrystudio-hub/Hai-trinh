class_name Weather
extends Node
## Thời tiết của trận (góp ý 4, mục 12): bình thường, mưa, bão. Chuyển kiểu thời tiết mượt trong TRANSITION_SECONDS
## giây; mỗi nhịp cập nhật biển (sóng to hơn, gió đổi chiều liên tục), ánh nắng, mưa 3D và sấm sét.
## Chỉ đổi hình ảnh và âm thanh, không đổi số liệu chiến đấu.

signal changed(data: WeatherData)
## Một tia sét vừa đánh, kèm giây chờ tới khi tiếng sấm tới (sét càng xa chờ càng lâu).
signal lightning_struck(thunder_delay: float)

const TRANSITION_SECONDS: float = 4.0
## Nạp lúc chạy, không dùng const preload (cùng lý do với tests/test_data.gd: .tres có script lớp riêng).
const PATHS: Dictionary[StringName, String] = {
	&"clear": "res://data/weather/clear.tres",
	&"rain": "res://data/weather/rain.tres",
	&"storm": "res://data/weather/storm.tres",
}
## Thời gian từ tia chớp tới tiếng sấm, giây.
const THUNDER_DELAY_MIN: float = 0.25
const THUNDER_DELAY_MAX: float = 1.6
## Độ sáng nắng ban đầu của bản đồ giảm tới mức này khi trời tối hẳn.
const SUN_DIM_MAX: float = 0.6

var data: WeatherData
## Giá trị đang hiển thị, đã nội suy giữa kiểu cũ và kiểu mới.
var wave_boost: float = 1.0
var wind_swing: float = 0.0
var wind_period: float = 24.0
var chop: float = 1.0
var wave_speed: float = 1.0
var bob_scale: float = 1.0
var rain: float = 0.0
var darkness: float = 0.0
var wind: float = 0.0
var strikes: int = 0

var ocean: Ocean
var sun: DirectionalLight3D
var rain_field: RainField
var island: Island
var lightning_overlay: LightningOverlay

var _sun_energy: float = 1.0
var _from: WeatherData
var _blend: float = 1.0
var _lightning_left: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = 4242
	data = by_id(&"clear")
	_from = data


## Nối vào các phần của trận; sun_energy là độ sáng nắng gốc của bản đồ.
func attach(target_ocean: Ocean, target_sun: DirectionalLight3D, rain_fx: RainField, lightning_fx: LightningOverlay) -> void:
	ocean = target_ocean
	sun = target_sun
	rain_field = rain_fx
	lightning_overlay = lightning_fx
	_sun_energy = sun.light_energy if sun != null else 1.0
	apply(0.0)


## Kiểu thời tiết theo id ("clear", "rain", "storm"); id lạ thì về bình thường.
static func by_id(id: StringName) -> WeatherData:
	return load(PATHS.get(id, PATHS[&"clear"]))


## Đổi thời tiết; immediate = true thì đổi ngay không nội suy.
func set_weather(next: WeatherData, immediate: bool = false) -> void:
	if next == data and _blend >= 1.0:
		return
	_from = _current_as_data()
	data = next
	_blend = 1.0 if immediate else 0.0
	_lightning_left = _next_lightning_gap() if data.has_lightning() else 0.0
	apply(0.0)
	changed.emit(data)


## Một nhịp (delta đã nhân tốc độ trận) tại đồng hồ time (cùng đồng hồ sóng).
func advance(delta: float, time: float) -> void:
	if _blend < 1.0:
		_blend = minf(_blend + delta / TRANSITION_SECONDS, 1.0)
	_update_lightning(delta)
	apply(time)


## Tính giá trị hiện tại và đẩy vào biển, nắng, mưa.
func apply(time: float) -> void:
	var t: float = smoothstep(0.0, 1.0, _blend)
	wave_boost = lerpf(_from.wave_boost, data.wave_boost, t)
	wind_swing = lerpf(_from.wind_swing, data.wind_swing, t)
	wind_period = lerpf(_from.wind_period, data.wind_period, t)
	chop = lerpf(_from.chop, data.chop, t)
	wave_speed = lerpf(_from.wave_speed, data.wave_speed, t)
	bob_scale = lerpf(_from.bob_scale, data.bob_scale, t)
	rain = lerpf(_from.rain, data.rain, t)
	darkness = lerpf(_from.darkness, data.darkness, t)
	wind = wind_angle(wind_swing, wind_period, time)
	if ocean != null:
		ocean.set_sea_state(wave_boost, wind, darkness, chop, wave_speed, rain)
	if island != null:
		island.bob_scale = bob_scale
	if sun != null:
		sun.light_energy = _sun_energy * (1.0 - darkness * SUN_DIM_MAX)
	if rain_field != null:
		rain_field.set_rain(rain, wind)


## Góc gió (radian) tại thời điểm time: hai dao động chồng nhau nên gió đổi chiều không đều nhịp.
static func wind_angle(swing: float, period: float, time: float) -> float:
	var base: float = TAU / maxf(period, 0.001)
	return swing * (0.7 * sin(time * base) + 0.3 * sin(time * base * 2.37 + 1.1))


## Khoảng cách tới tia chớp kế, theo kiểu thời tiết hiện tại.
func _next_lightning_gap() -> float:
	return _rng.randf_range(data.lightning_min_seconds, data.lightning_max_seconds)


func _update_lightning(delta: float) -> void:
	if not data.has_lightning():
		return
	_lightning_left -= delta
	if _lightning_left <= 0.0:
		_lightning_left = _next_lightning_gap()
		strike()


## Một tia sét đánh ngay (cũng dùng để thử).
func strike() -> void:
	strikes += 1
	var delay: float = _rng.randf_range(THUNDER_DELAY_MIN, THUNDER_DELAY_MAX)
	if lightning_overlay != null:
		lightning_overlay.strike(_rng.randf_range(0.15, 0.85))
	lightning_struck.emit(delay)
	Events.lightning_struck.emit(delay)


func _current_as_data() -> WeatherData:
	var snapshot: WeatherData = WeatherData.new()
	snapshot.wave_boost = wave_boost
	snapshot.wind_swing = wind_swing
	snapshot.wind_period = wind_period
	snapshot.chop = chop
	snapshot.wave_speed = wave_speed
	snapshot.bob_scale = bob_scale
	snapshot.rain = rain
	snapshot.darkness = darkness
	return snapshot
