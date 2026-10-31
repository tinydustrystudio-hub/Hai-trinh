class_name SoundBoard
extends Node
## Vài tiếng tạm của tháng 1 (kế hoạch bước 12): bắn, nổ, MEGA. Âm dựng bằng code lúc vào trận
## (không cần file âm thanh), phát qua một nhóm AudioStreamPlayer dùng xoay vòng.
## Giới hạn số lần phát mỗi loại để 10 khẩu Súng Máy bắn cùng lúc không thành một tràng ồn.
## Tắt khi Settings.sound_enabled là false.

enum Sound { SHOT, EXPLOSION, MEGA, THUNDER, CLICK }

const MIX_RATE: int = 22050
const PLAYERS: int = 8
## Khoảng cách tối thiểu giữa hai lần phát cùng loại, giây.
const MIN_GAP: Dictionary[Sound, float] = { Sound.SHOT: 0.07, Sound.EXPLOSION: 0.09, Sound.MEGA: 0.2, Sound.THUNDER: 0.5, Sound.CLICK: 0.05 }
const VOLUME_DB: Dictionary[Sound, float] = { Sound.SHOT: -16.0, Sound.EXPLOSION: -9.0, Sound.MEGA: -6.0, Sound.THUNDER: -4.0, Sound.CLICK: -12.0 }

## Số lần đã phát mỗi loại (để thử).
var played: Dictionary[Sound, int] = { Sound.SHOT: 0, Sound.EXPLOSION: 0, Sound.MEGA: 0, Sound.THUNDER: 0, Sound.CLICK: 0 }

var _streams: Dictionary[Sound, AudioStreamWAV] = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _last_played: Dictionary[Sound, float] = { Sound.SHOT: -1.0, Sound.EXPLOSION: -1.0, Sound.MEGA: -1.0, Sound.THUNDER: -1.0, Sound.CLICK: -1.0 }
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 7
	_streams[Sound.SHOT] = make_shot()
	_streams[Sound.EXPLOSION] = make_explosion()
	_streams[Sound.MEGA] = make_mega()
	_streams[Sound.THUNDER] = make_thunder()
	_streams[Sound.CLICK] = make_click()
	for i: int in PLAYERS:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "Player%d" % i
		add_child(player)
		_players.append(player)
	Events.enemy_killed.connect(func(_enemy: Enemy, _reward: int) -> void: play(Sound.EXPLOSION))
	Events.mega_started.connect(func(_tower: Node3D) -> void: play(Sound.MEGA))
	Events.tower_fired.connect(func(_tower: Node3D) -> void: play(Sound.SHOT))
	Events.lightning_struck.connect(_on_lightning)
	Events.ui_clicked.connect(func() -> void: play(Sound.CLICK))


## Phát một tiếng nếu đã đủ khoảng cách với lần trước cùng loại; trả true nếu đã phát.
func play(sound: Sound) -> bool:
	if not Settings.sound_enabled:
		return false
	var now: float = float(Time.get_ticks_msec()) / 1000.0
	if _last_played[sound] >= 0.0 and now - _last_played[sound] < MIN_GAP[sound]:
		return false
	_last_played[sound] = now
	played[sound] += 1
	var player: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = _streams[sound]
	player.volume_db = VOLUME_DB[sound]
	player.pitch_scale = _rng.randf_range(0.92, 1.08)
	if player.is_inside_tree():
		player.play()
	return true


## Tiếng sấm tới chậm hơn tia chớp thunder_delay giây.
func _on_lightning(thunder_delay: float) -> void:
	if not is_inside_tree():
		return
	await get_tree().create_timer(thunder_delay).timeout
	play(Sound.THUNDER)


func stream(sound: Sound) -> AudioStreamWAV:
	return _streams.get(sound)


## Tiếng súng: tiếng nổ lốp bốp ngắn 70 ms, nhiễu trắng tắt nhanh.
static func make_shot() -> AudioStreamWAV:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 11
	var count: int = int(MIX_RATE * 0.07)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	var previous: float = 0.0
	for i: int in count:
		var t: float = float(i) / float(count)
		var noise: float = rng.randf_range(-1.0, 1.0)
		# Lọc thông cao đơn giản để tiếng gọn, giòn.
		var crisp: float = noise - previous * 0.6
		previous = noise
		samples[i] = crisp * pow(1.0 - t, 3.0) * 0.8
	return _to_wav(samples)


## Tiếng nổ: nhiễu lọc trầm và một nhịp "thụp" 55 Hz, tắt dần trong 0,45 giây.
static func make_explosion() -> AudioStreamWAV:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 23
	var count: int = int(MIX_RATE * 0.45)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	var low: float = 0.0
	for i: int in count:
		var t: float = float(i) / float(count)
		low = lerpf(low, rng.randf_range(-1.0, 1.0), 0.12)
		var thump: float = sin(TAU * 55.0 * float(i) / float(MIX_RATE)) * exp(-t * 9.0)
		samples[i] = (low * 2.2 * exp(-t * 5.0) + thump * 0.7) * 0.7
	return _to_wav(samples)


## Tiếng MEGA: một nhịp quét lên từ 180 tới 900 Hz kèm âm bội, 0,7 giây.
static func make_mega() -> AudioStreamWAV:
	var count: int = int(MIX_RATE * 0.7)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	var phase: float = 0.0
	for i: int in count:
		var t: float = float(i) / float(count)
		var frequency: float = lerpf(180.0, 900.0, t * t)
		phase += TAU * frequency / float(MIX_RATE)
		var tone: float = sin(phase) * 0.6 + sin(phase * 2.0) * 0.25 + sin(phase * 3.01) * 0.12
		var envelope: float = smoothstep(0.0, 0.05, t) * (1.0 - smoothstep(0.75, 1.0, t))
		samples[i] = tone * envelope * 0.8
	return _to_wav(samples)


## Tiếng bấm nút: hai nốt ngắn đi lên (660 và 990 Hz), 90 ms, dịu tai.
static func make_click() -> AudioStreamWAV:
	var count: int = int(MIX_RATE * 0.09)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	for i: int in count:
		var t: float = float(i) / float(count)
		var frequency: float = 660.0 if t < 0.4 else 990.0
		var tone: float = sin(TAU * frequency * float(i) / float(MIX_RATE))
		samples[i] = tone * smoothstep(0.0, 0.05, t) * pow(1.0 - t, 2.0) * 0.6
	return _to_wav(samples)


## Tiếng sấm: một tiếng nứt ngắn rồi tiếng rền trầm lăn dài 1,8 giây (nhiễu lọc rất trầm, ba nhịp tắt dần).
static func make_thunder() -> AudioStreamWAV:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 31
	var count: int = int(MIX_RATE * 1.8)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(count)
	var low: float = 0.0
	var deeper: float = 0.0
	for i: int in count:
		var t: float = float(i) / float(count)
		var noise: float = rng.randf_range(-1.0, 1.0)
		low = lerpf(low, noise, 0.07)
		deeper = lerpf(deeper, low, 0.12)
		var crack: float = noise * exp(-t * 60.0) * 0.5
		var roll: float = 0.55 + 0.45 * sin(t * 17.0 + 1.3)
		samples[i] = (deeper * 9.0 * roll * exp(-t * 2.2) + crack) * 0.8
	return _to_wav(samples)


static func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples.size() * 2)
	for i: int in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav
