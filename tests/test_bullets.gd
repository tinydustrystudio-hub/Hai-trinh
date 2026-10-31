extends GutTest
## Vệt đạn MultiMesh: thêm vệt, tự tắt sau LIFETIME, không vượt số tối đa.

var _bullets: BulletRenderer


func before_each() -> void:
	_bullets = add_child_autofree(BulletRenderer.new())


func test_tracer_lives_briefly() -> void:
	_bullets.add_tracer(Vector3.ZERO, Vector3(0, 0, -10))
	assert_eq(_bullets.active_count(), 1)
	_bullets.advance(BulletRenderer.LIFETIME * 0.5)
	assert_eq(_bullets.multimesh.visible_instance_count, 1)
	_bullets.advance(BulletRenderer.LIFETIME)
	assert_eq(_bullets.active_count(), 0)
	assert_eq(_bullets.multimesh.visible_instance_count, 0)


func test_never_exceeds_capacity() -> void:
	for i: int in BulletRenderer.MAX_TRACERS + 50:
		_bullets.add_tracer(Vector3.ZERO, Vector3(i, 0, 1))
	_bullets.advance(0.001)
	assert_eq(_bullets.multimesh.visible_instance_count, BulletRenderer.MAX_TRACERS)
