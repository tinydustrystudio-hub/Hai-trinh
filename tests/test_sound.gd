extends GutTest
## Tiếng tạm (kế hoạch bước 12): dựng được ba tiếng, giới hạn số lần phát, tắt theo cài đặt âm thanh.

var _board: SoundBoard


func before_each() -> void:
	Settings.sound_enabled = true
	_board = add_child_autofree(SoundBoard.new())


func after_each() -> void:
	Settings.sound_enabled = true


func test_streams_are_built() -> void:
	for sound: SoundBoard.Sound in [SoundBoard.Sound.SHOT, SoundBoard.Sound.EXPLOSION, SoundBoard.Sound.MEGA]:
		var wav: AudioStreamWAV = _board.stream(sound)
		assert_not_null(wav)
		assert_gt(wav.data.size(), 1000)
	assert_almost_eq(_board.stream(SoundBoard.Sound.SHOT).get_length(), 0.07, 0.005)
	assert_almost_eq(_board.stream(SoundBoard.Sound.MEGA).get_length(), 0.7, 0.005)


func test_shots_are_throttled() -> void:
	assert_true(_board.play(SoundBoard.Sound.SHOT))
	for i: int in 20:
		_board.play(SoundBoard.Sound.SHOT)
	assert_eq(_board.played[SoundBoard.Sound.SHOT], 1, "nhiều phát cùng lúc chỉ kêu một lần")


func test_sound_off_is_silent() -> void:
	Settings.sound_enabled = false
	assert_false(_board.play(SoundBoard.Sound.EXPLOSION))
	assert_eq(_board.played[SoundBoard.Sound.EXPLOSION], 0)


func test_events_trigger_sounds() -> void:
	Events.mega_started.emit(autofree(Node3D.new()))
	assert_eq(_board.played[SoundBoard.Sound.MEGA], 1)
