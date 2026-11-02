class_name TestLayouts
extends RefCounted
## Bố cục thử có sẵn đảo vệ tinh: màn thật không có đảo cấp sẵn (đảo phụ chỉ có khi người chơi mua), nên các test cần đảo
## vệ tinh dựng bố cục từ chỗ đậu của màn.

const NORTH_DOCK: MapLayout = preload("res://data/maps/north_dock_layout.tres")


## Bố cục Bến Bắc với count đảo vệ tinh đậu ở các chỗ đậu đầu tiên.
static func with_satellites(count: int) -> MapLayout:
	var centers: PackedVector3Array = PackedVector3Array()
	for i: int in mini(count, NORTH_DOCK.satellite_docks.size()):
		centers.append(NORTH_DOCK.satellite_docks[i])
	return NORTH_DOCK.with_satellites(centers)
