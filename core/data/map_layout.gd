class_name MapLayout
extends Resource
## Bố cục một bản đồ trận: khối đảo, vị trí bệ, điểm của từng luồng và giới hạn camera.
## Mọi vị trí tính bằng đơn vị Godot trên mặt nước (y = 0); 1 ô = UNITS_PER_CELL đơn vị.

## 1 ô (đơn vị tầm trong GDD) = khoảng cách giữa hai bệ liền nhau.
const UNITS_PER_CELL: float = 4.0
## Số bệ lô cốt trên mỏm bến của đảo chính: luôn là 6 ở mọi màn (GDD mục 5.1).
const MAIN_ISLAND_PADS: int = 6
## Khe hở tối thiểu giữa mép đảo kéo thả với luồng và với đảo khác.
const ISLAND_GAP: float = 2.0
## Khe hở tối thiểu giữa mép đảo kéo thả với dải luồng.
const LANE_GAP: float = 0.5

@export var id: StringName = &""
## Khóa tên bản đồ trong bảng dịch.
@export var name_key: StringName = &""

@export_group("Trận")
## Thép khởi đầu (GDD mục 3.1, Hồi I mức Trung bình).
@export var starting_steel: int = 200
## Độ Nổi khởi đầu (kế hoạch tháng 1, mục 5.1).
@export var starting_buoyancy: int = 20

@export_group("Đảo")
## Tâm pháo đài lục giác (đảo chính), trên mặt nước.
@export var fortress_center: Vector3 = Vector3.ZERO
## Bán kính ngoài của pháo đài (từ tâm tới đỉnh lục giác của đê chắn sóng), đơn vị Godot.
@export var fortress_radius: float = 14.0
## Tâm các đảo vệ tinh; mỗi đảo mang một bệ ở giữa. Bệ không nằm trên đảo vệ tinh thì nằm trên mỏm bến.
@export var satellite_centers: PackedVector3Array = PackedVector3Array()
## Bán kính đảo vệ tinh (GDD mục 5.4 và 8.6: đường kính 2 ô).
@export var satellite_radius: float = 4.0
## Hướng từ mặt nước tới mặt trời (nắng chiếu từ một hướng).
@export var sun_direction: Vector3 = Vector3(0.45, 0.6, -0.65)


## Chỗ đậu của các đảo mua thêm cạnh đảo chính: đảo mua rồi nằm đây tới khi người chơi kéo ra chỗ tuỳ ý trong trận.
## Cách luồng đủ xa để không đè lên. Đảo cấp sẵn (satellite_centers) do từng màn tự sắp xếp.
@export var satellite_docks: PackedVector3Array = PackedVector3Array()

@export_group("Nhà giàn của màn")
## Nhà giàn cố định trên biển: tâm từng nhà giàn, chủng loại (old_oil_rig, ...) cùng thứ tự, và bán kính chiếm chỗ (tính cả bãi đáp).
## Mỗi nhà giàn mang một bệ lô cốt, nằm trong pad_positions ngay sau các bệ mỏm bến và trước các bệ đảo vệ tinh.
@export var platform_centers: PackedVector3Array = PackedVector3Array()
@export var platform_kinds: Array[StringName] = []
@export var platform_radius: float = 5.0

@export_group("Đảo vệ tinh của màn")
## Số đảo vệ tinh cấp sẵn đầu màn (đặt miễn phí). 0 = dùng đúng số đảo đã đặt sẵn trong satellite_centers.
@export var satellite_free_count: int = 0
## Giới hạn TỔNG số nhà giàn cố định và đảo vệ tinh (cấp sẵn và mua thêm) theo độ khó của màn: Dễ, Trung bình, Khó.
## Nhà giàn và đảo cấp sẵn luôn có; giới hạn chỉ quyết định còn mua thêm được bao nhiêu đảo.
@export var outpost_limits: PackedInt32Array = PackedInt32Array([12, 10, 8])
## Số đảo vệ tinh tối đa người chơi được đặt ở màn này, gồm cả đảo cấp sẵn và đảo mua thêm (GDD mục 5.4).
@export var satellite_max_count: int = 8

@export_group("Thời tiết và ánh sáng")
## Thời tiết của cả màn theo cốt truyện: clear, rain hoặc storm; không đổi giữa chừng.
@export var weather_id: StringName = &"clear"
## Ánh sáng của cả màn: day, dawn hoặc dusk.
@export var lighting_id: StringName = &"day"

@export_group("Công trình và tiện ích")
## Cấp từng công trình trên đảo chính (1, 3 hoặc 5; thiếu = cấp 1): wave_shield, repair_works, tidal_power, shipyard.
## Là số tạm cho tới khi có màn Căn cứ (P5) lưu cấp thật.
@export var building_levels: Dictionary[StringName, int] = {}
## Tiện ích của từng đảo vệ tinh theo thứ tự satellite_centers (radar_outpost, steel_depot, buoy_station, comms_tower).
## Thiếu thì lặp lần lượt bốn loại.
@export var satellite_utilities: Array[StringName] = []

@export_group("Bệ và luồng")
## Tâm của từng bệ lô cốt.
@export var pad_positions: PackedVector3Array = PackedVector3Array()
## Khóa tên của từng luồng trong bảng dịch, cùng thứ tự với lane_points.
@export var lane_name_keys: Array[StringName] = []
## Điểm của từng luồng, từ chỗ địch xuất hiện tới chỗ địch lọt vào đảo.
@export var lane_points: Array[PackedVector3Array] = []

@export_group("Camera")
## Vùng điểm nhìn của camera (trên mặt nước, theo x và z) được trượt tới khi thu nhỏ hết cỡ.
@export var camera_bounds: Rect2 = Rect2(-40.0, -40.0, 80.0, 60.0)
## Vùng điểm nhìn được trượt tới khi phóng to hết cỡ (giới hạn bản đồ); ở giữa thì nội suy.
@export var camera_zoom_bounds: Rect2 = Rect2(-60.0, -50.0, 120.0, 100.0)
## Điểm nhìn lúc vào trận.
@export var camera_start: Vector2 = Vector2.ZERO
## Khoảng cách từ camera tới điểm nhìn khi thu nhỏ hết cỡ (thấy toàn bộ chiến trường).
@export var camera_distance: float = 60.0
## Khoảng cách lúc vào trận (đảo chính chiếm khoảng 1/3 chiều cao màn hình); 0 = thu nhỏ hết cỡ.
@export var camera_start_distance: float = 0.0
## Khoảng cách khi phóng to hết cỡ (đảo chính gần đầy màn hình).
@export var camera_min_distance: float = 30.0
## Góc nghiêng của camera so với mặt nước, độ.
@export var camera_pitch_degrees: float = 55.0


## Khoảng cách camera lúc vào trận, kẹp trong giới hạn thu phóng.
func start_distance() -> float:
	var farthest: float = camera_distance
	if camera_start_distance <= 0.0:
		return farthest
	return clampf(camera_start_distance, minf(camera_min_distance, farthest), farthest)


## Đảo vệ tinh mà bệ index nằm trên, hoặc −1 nếu bệ nằm trên mỏm bến.
func satellite_index_of_pad(index: int) -> int:
	var pad: Vector3 = pad_positions[index]
	for k: int in satellite_centers.size():
		var center: Vector3 = satellite_centers[k]
		if Vector2(center.x - pad.x, center.z - pad.z).length() < satellite_radius * 0.5:
			return k
	return -1


## Nhà giàn mà bệ index nằm trên, hoặc −1.
func platform_index_of_pad(index: int) -> int:
	var pad: Vector3 = pad_positions[index]
	for k: int in platform_centers.size():
		if Vector2(platform_centers[k].x - pad.x, platform_centers[k].z - pad.z).length() < 1.0:
			return k
	return -1


func platform_kind(index: int) -> StringName:
	return platform_kinds[index] if index < platform_kinds.size() else Platforms.OLD_OIL_RIG


## Số đảo cấp sẵn thật sự.
func free_satellites() -> int:
	return satellite_free_count if satellite_free_count > 0 else satellite_centers.size()


## Giới hạn tổng nhà giàn và đảo vệ tinh ở độ khó level (Difficulty.Level).
func outpost_limit(level: int = Difficulty.Level.NORMAL) -> int:
	if outpost_limits.is_empty():
		return fixed_outposts() + maxi(satellite_max_count - free_satellites(), 0)
	return outpost_limits[clampi(level, 0, outpost_limits.size() - 1)]


## Nhà giàn và đảo cấp sẵn: luôn có ở màn này.
func fixed_outposts() -> int:
	return platform_centers.size() + free_satellites()


## Số đảo mua thêm được ở màn này ở độ khó level: không quá số đảo tối đa của màn và không làm tổng vượt giới hạn.
func extra_satellites(level: int = Difficulty.Level.NORMAL) -> int:
	var by_max: int = maxi(satellite_max_count - free_satellites(), 0)
	var by_limit: int = maxi(outpost_limit(level) - fixed_outposts(), 0)
	return mini(by_max, by_limit)


## Số bệ trên mỏm bến của đảo chính.
func pier_pad_count() -> int:
	var count: int = 0
	for i: int in pad_count():
		if is_pier_pad(i):
			count += 1
	return count


var _lane_curves: Array[Curve3D] = []


func lane_count() -> int:
	return lane_points.size()


func pad_count() -> int:
	return pad_positions.size()


## Bệ nằm trên đảo vệ tinh (trùng tâm một đảo vệ tinh) hay trên mỏm bến của đảo chính.
func is_satellite_pad(index: int) -> bool:
	var pad: Vector3 = pad_positions[index]
	for center: Vector3 in satellite_centers:
		if Vector2(center.x - pad.x, center.z - pad.z).length() < satellite_radius * 0.5:
			return true
	return false


## Bệ nằm trên mỏm bến của đảo chính (không phải bệ đảo vệ tinh hay bệ nhà giàn).
func is_pier_pad(index: int) -> bool:
	return not is_satellite_pad(index) and platform_index_of_pad(index) < 0


## Cấp của công trình (1, 3 hoặc 5), mặc định 1.
func building_level(building: StringName) -> int:
	return clampi(building_levels.get(building, 1), 1, 5)


## Tiện ích của đảo vệ tinh thứ index.
func satellite_utility(index: int) -> StringName:
	if index < satellite_utilities.size():
		return satellite_utilities[index]
	return SatelliteUtilities.IDS[index % SatelliteUtilities.IDS.size()]


## Bản sao của bố cục với các đảo vệ tinh đặt ở centers (đúng thứ tự), mỗi đảo mang tiện ích utilities[i] (thiếu thì theo vòng lặp).
## Bệ trên mỏm bến giữ nguyên; bệ của đảo vệ tinh được dựng lại ở tâm từng đảo.
func with_satellites(centers: PackedVector3Array, utilities: Array[StringName] = []) -> MapLayout:
	var result: MapLayout = duplicate() as MapLayout
	var pads: PackedVector3Array = PackedVector3Array()
	for i: int in pad_positions.size():
		if not is_satellite_pad(i):
			pads.append(pad_positions[i])
	for center: Vector3 in centers:
		pads.append(center)
	result.pad_positions = pads
	result.satellite_centers = centers
	result.satellite_utilities = utilities.duplicate()
	return result


## Điểm point có đặt được tâm một đảo vệ tinh không (đảo kéo thả tự do): trong vùng biển chơi, cách đảo chính đủ xa,
## không đè luồng địch, không chồng đảo vệ tinh khác (bỏ qua đảo thứ ignore_index, là chính đảo đang kéo).
func island_spot_valid(point: Vector3, ignore_index: int = -1) -> bool:
	var flat: Vector2 = Vector2(point.x, point.z)
	var bounds: Rect2 = camera_zoom_bounds.grow(-satellite_radius)
	if not bounds.has_point(flat):
		return false
	if flat.distance_to(Vector2(fortress_center.x, fortress_center.z)) < fortress_radius * 2.0:
		return false
	for k: int in satellite_centers.size():
		if k != ignore_index and flat.distance_to(Vector2(satellite_centers[k].x, satellite_centers[k].z)) < satellite_radius * 2.0 + ISLAND_GAP:
			return false
	for center: Vector3 in platform_centers:
		if flat.distance_to(Vector2(center.x, center.z)) < platform_radius + satellite_radius + ISLAND_GAP:
			return false
	var clearance: float = satellite_radius + Lane.RIBBON_WIDTH * 0.5 + LANE_GAP
	if _lane_curves.size() != lane_points.size():
		_lane_curves.clear()
		for points: PackedVector3Array in lane_points:
			_lane_curves.append(Lane.build_curve(points))
	for curve: Curve3D in _lane_curves:
		var closest: Vector3 = curve.get_closest_point(point)
		if Vector2(closest.x - point.x, closest.z - point.z).length() < clearance:
			return false
	return true
