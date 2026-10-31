extends GutTest
## Rung máy và nhạc nền (góp ý 3 của đạo diễn): rung khi địch đâm đảo, khi nổ MEGA, khi tàu trùm nổ;
## không rung liên hồi; tắt theo cài đặt. Nhạc nền lặp, tắt theo âm thanh hoặc nhạc.

const SKIFF: EnemyData = preload("res://data/enemies/raider_skiff.tres")

var _haptics: Haptics


func before_each() -> void:
	Settings.vibration_enabled = true
	_haptics = add_child_autofree(Haptics.new())


func after_each() -> void:
	Settings.vibration_enabled = true
	Settings.sound_enabled = true
	Settings.music_enabled = true


func _enemy(data: EnemyData) -> Enemy:
	var enemy: Enemy = autofree(Enemy.new())
	enemy.data = data
	return enemy


func test_leak_mega_and_boss_vibrate() -> void:
	Events.enemy_leaked.emit(_enemy(SKIFF), 1)
	Events.mega_started.emit(autofree(Node3D.new()))
	var boss_data: EnemyData = SKIFF.duplicate()
	boss_data.is_boss = true
	Events.enemy_killed.emit(_enemy(boss_data), 10)
	assert_eq(_haptics.pulses[Haptics.Kind.LEAK], 1)
	assert_eq(_haptics.pulses[Haptics.Kind.MEGA], 1)
	assert_eq(_haptics.pulses[Haptics.Kind.BOSS], 1)


func test_ordinary_kill_does_not_vibrate() -> void:
	Events.enemy_killed.emit(_enemy(SKIFF), 5)
	assert_eq(_haptics.pulses[Haptics.Kind.BOSS], 0)


func test_leaks_are_throttled() -> void:
	for i: int in 10:
		Events.enemy_leaked.emit(_enemy(SKIFF), 1)
	assert_eq(_haptics.pulses[Haptics.Kind.LEAK], 1, "nhiều tàu đâm cùng lúc chỉ rung một lần")


func test_vibration_off() -> void:
	Settings.vibration_enabled = false
	assert_false(_haptics.pulse(Haptics.Kind.MEGA))
	assert_eq(_haptics.pulses[Haptics.Kind.MEGA], 0)


func test_boss_vibrates_longest() -> void:
	assert_gt(Haptics.DURATION_MS[Haptics.Kind.BOSS], Haptics.DURATION_MS[Haptics.Kind.MEGA])
	assert_gt(Haptics.DURATION_MS[Haptics.Kind.MEGA], Haptics.DURATION_MS[Haptics.Kind.LEAK])


func test_music_loops_and_follows_settings() -> void:
	var music: MusicPlayer = add_child_autofree(MusicPlayer.new())
	var stream: AudioStreamOggVorbis = music.stream as AudioStreamOggVorbis
	assert_not_null(stream)
	assert_true(stream.loop, "nhạc lặp liền")
	assert_almost_eq(stream.get_length(), 38.4, 0.2)
	assert_true(music.playing)
	Settings.music_enabled = false
	assert_false(music.playing)
	Settings.music_enabled = true
	assert_true(music.playing)
	Settings.sound_enabled = false
	assert_false(music.playing, "tắt âm thanh thì tắt cả nhạc")
