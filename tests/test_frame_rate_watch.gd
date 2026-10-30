extends GutTest
## Hạ chất lượng nước khi dưới 30 khung/giây liên tục 5 giây (kế hoạch mục 7).

func test_triggers_after_five_seconds_below() -> void:
	var watch: FrameRateWatch = FrameRateWatch.new(30.0, 5.0)
	# Bước 0,25 giây cộng không sai số dấu phẩy động.
	for i: int in 19:
		assert_false(watch.update(25.0, 0.25))
	assert_true(watch.update(25.0, 0.25))
	assert_false(watch.update(25.0, 0.25), "chỉ báo một lần")


func test_good_frame_resets_timer() -> void:
	var watch: FrameRateWatch = FrameRateWatch.new(30.0, 5.0)
	for i: int in 40:
		watch.update(20.0, 0.1)
	watch.update(45.0, 0.1)
	for i: int in 40:
		assert_false(watch.update(20.0, 0.1))


func test_exactly_threshold_is_fine() -> void:
	var watch: FrameRateWatch = FrameRateWatch.new(30.0, 5.0)
	for i: int in 100:
		assert_false(watch.update(30.0, 0.1))


func test_reset() -> void:
	var watch: FrameRateWatch = FrameRateWatch.new(30.0, 1.0)
	watch.update(10.0, 2.0)
	assert_true(watch.triggered)
	watch.reset()
	assert_false(watch.triggered)
