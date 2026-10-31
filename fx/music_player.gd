class_name MusicPlayer
extends AudioStreamPlayer
## Nhạc nền tạm của tháng 1 (góp ý 3 của đạo diễn: có nhạc khi thử cho đỡ nhàm chán). Bản nhạc dựng bằng
## tools/make_music.py, lặp liền mạch. Chỉ phát khi Settings.sound_enabled và Settings.music_enabled.
## Không theo tốc độ trận: tạm dừng hay tua ×2 vẫn phát bình thường.

const MUSIC: AudioStream = preload("res://assets/audio/music_theme.ogg")
const VOLUME: float = -15.0


func _ready() -> void:
	var looped: AudioStreamOggVorbis = (MUSIC as AudioStreamOggVorbis).duplicate()
	looped.loop = true
	stream = looped
	volume_db = VOLUME
	process_mode = Node.PROCESS_MODE_ALWAYS
	Settings.audio_changed.connect(apply_settings)
	apply_settings()


## Phát hoặc dừng theo cài đặt âm thanh hiện tại.
func apply_settings() -> void:
	var wanted: bool = should_play()
	if wanted and not playing and is_inside_tree():
		play()
	elif not wanted and playing:
		stop()


static func should_play() -> bool:
	return Settings.sound_enabled and Settings.music_enabled
