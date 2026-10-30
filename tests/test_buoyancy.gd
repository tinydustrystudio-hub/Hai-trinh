extends GutTest
## Độ Nổi: trừ khi lọt, báo chìm đúng một lần, đảo nghiêng theo phần đã mất.

var _buoyancy: Buoyancy


func before_each() -> void:
	_buoyancy = add_child_autofree(Buoyancy.new())
	watch_signals(_buoyancy)
	_buoyancy.reset(20)


func test_leak_reduces() -> void:
	assert_false(_buoyancy.take_leak(3))
	assert_eq(_buoyancy.value, 17)
	assert_signal_emitted_with_parameters(_buoyancy, "changed", [17, 20])


func test_depletes_once_at_zero() -> void:
	_buoyancy.take_leak(19)
	assert_true(_buoyancy.take_leak(3))
	assert_eq(_buoyancy.value, 0)
	assert_true(_buoyancy.is_sunk())
	assert_false(_buoyancy.take_leak(1))
	assert_signal_emit_count(_buoyancy, "depleted", 1)


func test_tilt_grows_with_damage() -> void:
	assert_eq(_buoyancy.tilt_degrees(), 0.0)
	_buoyancy.take_leak(10)
	assert_almost_eq(_buoyancy.tilt_degrees(), Buoyancy.MAX_TILT_DEGREES * 0.5, 0.0001)
