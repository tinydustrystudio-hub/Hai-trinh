extends GutTest
## Độ cao sóng trên CPU: biên độ của một sóng bằng độ dốc ÷ số sóng k.

func test_single_wave_amplitude() -> void:
	var waves: Array[Vector4] = [Vector4(1, 0, 0.1, 20.0)]
	var k: float = TAU / 20.0
	var amplitude: float = 0.1 / k
	# Đỉnh sóng ở x = bước sóng/4 khi t = 0.
	assert_almost_eq(Ocean.wave_height(waves, 1, 5.0, 0.0, 0.0), amplitude, 0.0001)
	assert_almost_eq(Ocean.wave_height(waves, 1, 0.0, 0.0, 0.0), 0.0, 0.0001)


func test_wave_count_limits_layers() -> void:
	var waves: Array[Vector4] = [Vector4(1, 0, 0.1, 20.0), Vector4(0, 1, 0.1, 10.0)]
	var one: float = Ocean.wave_height(waves, 1, 3.0, 2.0, 0.5)
	var both: float = Ocean.wave_height(waves, 2, 3.0, 2.0, 0.5)
	var second_only: float = Ocean.wave_height([waves[1]] as Array[Vector4], 1, 3.0, 2.0, 0.5)
	assert_almost_eq(both, one + second_only, 0.0001)


func test_zero_waves_is_flat() -> void:
	var waves: Array[Vector4] = [Vector4(1, 0, 0.1, 20.0)]
	assert_eq(Ocean.wave_height(waves, 0, 3.0, 2.0, 0.5), 0.0)
