class_name Island
extends Node3D
## Đảo của bản đồ trận, dựng từ MapLayout: pháo đài lục giác của Liên Minh ở giữa (có mỏm bến mang bệ và
## đèn báo hướng địch), các đảo vệ tinh mang bệ, phao cam; bóng giả trên mặt nước và dải bọt quanh chân đảo.
## Pháo đài và các bệ trên mỏm bến nghiêng theo Độ Nổi; đảo vệ tinh là phao riêng nên đứng yên.

const PAD_SCENE: PackedScene = preload("res://battle/map/tower_pad.tscn")
const FOAM_SHADER: Shader = preload("res://battle/map/foam.gdshader")
## Độ cao dải bọt và bóng giả: ngang đỉnh sóng nhẹ.
## Các công trình có thể thay bằng mô hình Blender theo cấp.
const BUILDING_IDS: Array[StringName] = [&"wave_shield", &"repair_works", &"tidal_power", &"shipyard"]
const FOAM_Y: float = 0.2
const SHADOW_Y: float = 0.16
const SHADOW_ALPHA: float = 0.42

## Dập dìu: đảo vệ tinh bán kính 4 (2 ô) là chuẩn; đảo lớn hơn dập dìu ít hơn tỉ lệ nghịch với bán kính.
const REFERENCE_RADIUS: float = 4.0
## Chỉ lấy một phần độ cao sóng (nhấp nhô ít thôi) và một phần độ dốc sóng.
const HEAVE_SCALE: float = 0.6
const ROCK_SCALE: float = 0.5
const MAX_ROCK_DEGREES: float = 1.5
## Giới hạn nhấp nhô xuống và lên (đơn vị Godot) để sàn đảo luôn nổi trên mặt nước lặng quanh đảo.
const HEAVE_MIN: float = -0.15
const HEAVE_MAX: float = 0.9
## Bão lắc đảo nhiều hơn nhưng tối đa gấp chừng này lần mức bình thường, để mép đảo không chìm.
const MAX_ROCK_SCALE: float = 1.6

static var _solid: StandardMaterial3D
static var _lamp: StandardMaterial3D
static var _shadow: StandardMaterial3D
static var _foam: ShaderMaterial

var pads: Array[TowerPad] = []
var beacons: LaneBeacons
## Từng đảo vệ tinh, mỗi đảo một nút để dập dìu riêng.
var satellites: Array[Node3D] = []
## Từng nhà giàn cố định (không dập dìu).
var platforms: Array[Node3D] = []
## Hệ số dập dìu của thời tiết (bão cho đảo dập dìu nhiều hơn).
var bob_scale: float = 1.0

var _body: Node3D
var _tilt_degrees: float = 0.0
var _body_rock: Vector3 = Vector3.ZERO
var _fortress_radius: float = 14.0
var _satellite_radius: float = 4.0
var _layout: MapLayout


func build(layout: MapLayout) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	pads.clear()
	satellites.clear()
	platforms.clear()
	_layout = layout
	_fortress_radius = layout.fortress_radius
	_satellite_radius = layout.satellite_radius
	_tilt_degrees = 0.0
	_body_rock = Vector3.ZERO
	_body = Node3D.new()
	_body.name = "Body"
	_body.position = layout.fortress_center
	add_child(_body)
	var fortress_offset: Transform3D = Transform3D(Basis.IDENTITY, -layout.fortress_center)
	_add_mesh(_body, "Fortress", AllianceFortress.build_fortress(layout), solid_material(), fortress_offset)
	_add_mesh(_body, "Lamp", AllianceFortress.build_lamp(layout), _lamp_material(), fortress_offset)
	# Công trình dựng bằng Blender (toạ độ cục bộ của đảo chính), theo cấp trong layout.
	for id: StringName in BUILDING_IDS:
		var model: ArrayMesh = ModelMesh.load_mesh(AllianceFortress.building_model_name(id, layout.building_level(id)))
		if model != null:
			_add_mesh(_body, "Building_%s" % String(id), model, solid_material())
	beacons = LaneBeacons.new()
	beacons.name = "LaneBeacons"
	_body.add_child(beacons)
	beacons.build(layout, fortress_offset)
	_add_mesh(self, "Buoys", AllianceFortress.build_buoys(layout), solid_material())
	for k: int in layout.satellite_centers.size():
		var satellite: Node3D = Node3D.new()
		satellite.name = "Satellite%d" % k
		satellite.position = layout.satellite_centers[k]
		add_child(satellite)
		_add_mesh(satellite, "Mesh", AllianceFortress.build_satellite(layout, k), solid_material())
		var utility: StringName = layout.satellite_utility(k)
		if SatelliteUtilities.has_model(utility):
			_add_mesh(satellite, "Utility", ModelMesh.load_mesh(SatelliteUtilities.model_name(utility)), solid_material(),
				SatelliteUtilities.model_transform(SatelliteUtilities.direction_for(layout, k)))
		satellites.append(satellite)
	for k: int in layout.platform_centers.size():
		var kind: StringName = layout.platform_kind(k)
		var platform: Node3D = Node3D.new()
		platform.name = "Platform%d" % k
		platform.position = layout.platform_centers[k]
		platform.rotation.y = Platforms.yaw_for(layout.platform_centers[k], layout.fortress_center)
		add_child(platform)
		platforms.append(platform)
		if Platforms.has_model(kind):
			_add_mesh(platform, "Model", ModelMesh.load_mesh(Platforms.model_name(kind)), solid_material())
	_add_mesh(self, "Shadow", build_shadow(layout), _shadow_material())
	_add_mesh(self, "Foam", build_foam(layout), _foam_material())
	for i: int in layout.pad_positions.size():
		var pad: TowerPad = PAD_SCENE.instantiate()
		pad.name = "TowerPad%d" % i
		pad.pad_index = i
		var satellite_index: int = layout.satellite_index_of_pad(i)
		var platform_index: int = layout.platform_index_of_pad(i)
		if platform_index >= 0:
			# Bệ nằm trên sàn nhà giàn: phần trên của bệ ngang mặt sàn.
			pad.position = Vector3(0.0, Platforms.deck_height(layout.platform_kind(platform_index)) - TowerPad.TOP_HEIGHT, 0.0)
			platforms[platform_index].add_child(pad)
		elif satellite_index >= 0:
			pad.position = layout.pad_positions[i] - layout.satellite_centers[satellite_index]
			satellites[satellite_index].add_child(pad)
		else:
			pad.position = layout.pad_positions[i] - layout.fortress_center
			_body.add_child(pad)
		pads.append(pad)


## Bật hoặc tắt đèn báo hướng địch của một luồng.
func set_lane_warning(lane_index: int, active: bool) -> void:
	if beacons != null:
		beacons.set_active(lane_index, active)


## Nghiêng pháo đài: mép phía Bắc (−z) chìm xuống.
func set_tilt(degrees: float) -> void:
	_tilt_degrees = degrees
	_apply_body_pose()


func tilt_degrees() -> float:
	return _tilt_degrees


## Dập dìu theo sóng (góp ý 4): mỗi đảo nhấp nhô và lắc nhẹ theo độ cao sóng dưới chân nó;
## đảo càng to càng ít dập dìu. time là đồng hồ sóng của mặt nước (giây).
func bob(ocean: Ocean, time: float) -> void:
	if _layout == null:
		return
	var body_pose: Vector3 = sample_pose(ocean, _layout.fortress_center, _fortress_radius, time, bob_scale)
	_body.position = _layout.fortress_center + Vector3(0.0, body_pose.x, 0.0)
	_body_rock = Vector3(body_pose.y, 0.0, body_pose.z)
	_apply_body_pose()
	for k: int in satellites.size():
		var center: Vector3 = _layout.satellite_centers[k]
		var pose: Vector3 = sample_pose(ocean, center, _satellite_radius, time, bob_scale)
		satellites[k].position = center + Vector3(0.0, pose.x, 0.0)
		satellites[k].rotation_degrees = Vector3(pose.y, 0.0, pose.z)


func _apply_body_pose() -> void:
	if _body != null:
		_body.rotation_degrees = Vector3(-_tilt_degrees + _body_rock.x, 0.0, _body_rock.z)


## Độ nhấp nhô và lắc của một đảo tâm center, bán kính radius: (độ cao, nghiêng quanh x, nghiêng quanh z), độ.
static func sample_pose(ocean: Ocean, center: Vector3, radius: float, time: float, scale: float = 1.0) -> Vector3:
	var gain: float = bob_gain(radius) * scale
	var reach: float = maxf(radius * 0.6, 1.0)
	var here: float = ocean.raw_height_at(center.x, center.z)
	var north: float = ocean.raw_height_at(center.x, center.z - reach)
	var south: float = ocean.raw_height_at(center.x, center.z + reach)
	var east: float = ocean.raw_height_at(center.x + reach, center.z)
	var west: float = ocean.raw_height_at(center.x - reach, center.z)
	# Bắc (−z) cao hơn nam thì mũi bắc ngẩng lên: quay quanh x theo chiều âm đảo dấu.
	var pitch: float = clampf(rad_to_deg(atan2(north - south, reach * 2.0)) * gain * ROCK_SCALE, -MAX_ROCK_DEGREES * minf(scale, MAX_ROCK_SCALE), MAX_ROCK_DEGREES * minf(scale, MAX_ROCK_SCALE))
	var roll: float = clampf(rad_to_deg(atan2(west - east, reach * 2.0)) * gain * ROCK_SCALE, -MAX_ROCK_DEGREES * minf(scale, MAX_ROCK_SCALE), MAX_ROCK_DEGREES * minf(scale, MAX_ROCK_SCALE))
	# Sóng bão cao thì đảo nhấp nhô theo nhưng bị giới hạn để sàn luôn nổi trên mặt nước lặng quanh đảo.
	return Vector3(clampf(here * gain * HEAVE_SCALE, HEAVE_MIN, HEAVE_MAX), -pitch, roll)


## Hệ số dập dìu theo cỡ đảo: 1 ở đảo bán kính REFERENCE_RADIUS, giảm theo tỉ lệ nghịch khi đảo to hơn.
static func bob_gain(radius: float) -> float:
	return clampf(REFERENCE_RADIUS / maxf(radius, 0.1), 0.1, 1.0)


## Dựng lại bóng và bọt theo vị trí đảo vệ tinh mới (đảo vừa được kéo ra); layout là bố cục đã dùng khi build.
func relayout(layout: MapLayout) -> void:
	_layout = layout
	var shadow: MeshInstance3D = get_node_or_null("Shadow") as MeshInstance3D
	if shadow != null:
		shadow.mesh = build_shadow(layout)
	var foam: MeshInstance3D = get_node_or_null("Foam") as MeshInstance3D
	if foam != null:
		foam.mesh = build_foam(layout)


## Bệ gần điểm trên mặt nước nhất, trong bán kính max_distance; không có thì trả null.
func pad_near(point: Vector3, max_distance: float) -> TowerPad:
	var best: TowerPad = null
	var best_distance: float = max_distance
	for pad: TowerPad in pads:
		if pad.locked:
			continue
		var at: Vector3 = pad.global_position if pad.is_inside_tree() else pad.position
		var d: float = Vector2(at.x - point.x, at.z - point.z).length()
		if d <= best_distance:
			best = pad
			best_distance = d
	return best


## Bóng giả: lục giác của pháo đài và vòng tròn của đảo vệ tinh, dời theo hướng ngược nắng, mép mềm.
static func build_shadow(layout: MapLayout) -> ArrayMesh:
	var st: SurfaceTool = MeshKit.begin()
	var sun: Vector3 = layout.sun_direction.normalized()
	var away: Vector3 = -Vector3(sun.x, 0.0, sun.z).normalized()
	var length: float = 1.0 / maxf(sun.y, 0.2)
	var r: float = layout.fortress_radius
	_soft_disc(st, layout.fortress_center + away * r * 0.1 * length, r * 0.96, r * 0.3, 6, 0.0)
	for center: Vector3 in layout.satellite_centers:
		_soft_disc(st, center + away * 0.6 * length, layout.satellite_radius, 1.2, 20, 0.0)
	for center: Vector3 in layout.platform_centers:
		_soft_disc(st, center + away * 1.2 * length, layout.platform_radius * 0.7, 1.6, 20, 0.0)
	return MeshKit.commit(st)


## Dải bọt: quanh lục giác pháo đài, hai mép và đầu mỗi mỏm bến, quanh đảo vệ tinh và phao.
static func build_foam(layout: MapLayout) -> ArrayMesh:
	var st: SurfaceTool = MeshKit.begin()
	var c: Vector3 = layout.fortress_center
	var r: float = layout.fortress_radius
	_band(st, _polygon(c, r + 0.15, 6, 0.0), 2.6)
	for i: int in layout.pad_count():
		if not layout.is_pier_pad(i):
			continue
		var pad: Vector3 = layout.pad_positions[i]
		var dir: Vector3 = Vector3(pad.x - c.x, 0.0, pad.z - c.z).normalized()
		var side: Vector3 = Vector3(-dir.z, 0.0, dir.x)
		var start: Vector3 = c + dir * (r * cos(PI / 6.0) + 1.0)
		var finish: Vector3 = Vector3(pad.x, 0.0, pad.z) - dir * AllianceFortress.PIER_END_RADIUS
		for s: float in [-1.0, 1.0]:
			var edge: Vector3 = side * s * AllianceFortress.PIER_WIDTH * 0.5
			_strip(st, start + edge, finish + edge, side * s, 1.4)
		_band(st, _polygon(Vector3(pad.x, 0.0, pad.z), AllianceFortress.PIER_END_RADIUS + 0.05, 20, 0.0), 1.8)
	for center: Vector3 in layout.satellite_centers:
		_band(st, _polygon(center, layout.satellite_radius + 0.1, 24, 0.0), 1.8)
	for center: Vector3 in layout.platform_centers:
		_band(st, _polygon(center, layout.platform_radius * 0.62, 20, 0.0), 1.6)
	for buoy: Vector3 in AllianceFortress.buoy_positions(layout):
		_band(st, _polygon(buoy, 0.5, 10, 0.0), 0.9)
	return MeshKit.commit(st)


static func _polygon(center: Vector3, radius: float, sides: int, yaw: float) -> PackedVector3Array:
	var points: PackedVector3Array = PackedVector3Array()
	for i: int in sides:
		var a: float = yaw + TAU * float(i) / float(sides)
		points.append(Vector3(center.x + cos(a) * radius, FOAM_Y, center.z + sin(a) * radius))
	return points


## Dải bọt quanh một đa giác lồi khép kín; UV.x = 0 ở mép đảo, 1 ở mép ngoài; UV.y chạy theo chu vi.
static func _band(st: SurfaceTool, outline: PackedVector3Array, width: float) -> void:
	var count: int = outline.size()
	var centroid: Vector3 = Vector3.ZERO
	for p: Vector3 in outline:
		centroid += p
	centroid /= float(count)
	var travelled: float = 0.0
	for i: int in count:
		var a: Vector3 = outline[i]
		var b: Vector3 = outline[(i + 1) % count]
		var oa: Vector3 = a + Vector3(a.x - centroid.x, 0.0, a.z - centroid.z).normalized() * width
		var ob: Vector3 = b + Vector3(b.x - centroid.x, 0.0, b.z - centroid.z).normalized() * width
		var next: float = travelled + a.distance_to(b)
		_uv_quad(st, a, b, ob, oa, Vector2(0.0, travelled), Vector2(0.0, next), Vector2(1.0, next), Vector2(1.0, travelled))
		travelled = next


## Dải bọt thẳng dọc một mép, loang ra theo hướng outward.
static func _strip(st: SurfaceTool, from: Vector3, to: Vector3, outward: Vector3, width: float) -> void:
	var a: Vector3 = Vector3(from.x, FOAM_Y, from.z)
	var b: Vector3 = Vector3(to.x, FOAM_Y, to.z)
	var length: float = a.distance_to(b)
	_uv_quad(st, a, b, b + outward * width, a + outward * width, Vector2(0.0, 0.0), Vector2(0.0, length), Vector2(1.0, length), Vector2(1.0, 0.0))


static func _uv_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2) -> void:
	for pair: Array in [[a, ua], [b, ub], [c, uc], [a, ua], [c, uc], [d, ud]]:
		st.set_uv(pair[1])
		st.set_normal(Vector3.UP)
		st.add_vertex(pair[0])


## Đĩa bóng: đậm ở trong, mờ dần ra mép trong khoảng soft.
static func _soft_disc(st: SurfaceTool, center: Vector3, radius: float, soft: float, sides: int, yaw: float) -> void:
	var inner: Color = Color(0.0, 0.02, 0.06, SHADOW_ALPHA)
	var outer: Color = Color(0.0, 0.02, 0.06, 0.0)
	var mid: Vector3 = Vector3(center.x, SHADOW_Y, center.z)
	for i: int in sides:
		var a0: float = yaw + TAU * float(i) / float(sides)
		var a1: float = yaw + TAU * float(i + 1) / float(sides)
		var d0: Vector3 = Vector3(cos(a0), 0.0, sin(a0))
		var d1: Vector3 = Vector3(cos(a1), 0.0, sin(a1))
		MeshKit.tri(st, mid, mid + d0 * radius, mid + d1 * radius, Vector3.UP, inner, inner, inner)
		MeshKit.quad(st, mid + d0 * radius, mid + d1 * radius, mid + d1 * (radius + soft), mid + d0 * (radius + soft), Vector3.UP, inner, outer)


static func solid_material() -> StandardMaterial3D:
	if _solid == null:
		_solid = StandardMaterial3D.new()
		_solid.vertex_color_use_as_albedo = true
		# Nền đảo trắng ngà hơi chói dưới nắng và glow (góp ý 4): hạ độ sáng chung và ngả lạnh một chút.
		_solid.albedo_color = Color(0.8, 0.82, 0.85)
		_solid.roughness = 0.85
	return _solid


static func _lamp_material() -> StandardMaterial3D:
	if _lamp == null:
		_lamp = StandardMaterial3D.new()
		_lamp.albedo_color = AllianceFortress.LAMP
		_lamp.emission_enabled = true
		_lamp.emission = AllianceFortress.LAMP
		_lamp.emission_energy_multiplier = 3.0
	return _lamp


static func _shadow_material() -> StandardMaterial3D:
	if _shadow == null:
		_shadow = StandardMaterial3D.new()
		_shadow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_shadow.vertex_color_use_as_albedo = true
		_shadow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_shadow.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		_shadow.render_priority = -2
	return _shadow


static func _foam_material() -> ShaderMaterial:
	if _foam == null:
		_foam = ShaderMaterial.new()
		_foam.shader = FOAM_SHADER
		_foam.set_shader_parameter(&"noise_tex", Ocean.foam_noise())
		_foam.render_priority = -1
	return _foam


func _add_mesh(parent: Node3D, node_name: String, mesh: Mesh, material: Material, xform: Transform3D = Transform3D.IDENTITY) -> void:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.transform = xform
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
