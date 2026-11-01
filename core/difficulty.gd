class_name Difficulty
extends RefCounted
## Ba mức độ khó của mỗi màn (GDD mục 2.6): Dễ, Trung bình, Khó. Màn dùng chung một bản đồ, chỉ đổi tham số;
## ở đây là mức đang chơi và cách đổi từ/ra id.

enum Level { EASY, NORMAL, HARD }

const IDS: Array[StringName] = [&"easy", &"normal", &"hard"]
const NAME_KEYS: Array[StringName] = [&"DIFFICULTY_EASY", &"DIFFICULTY_NORMAL", &"DIFFICULTY_HARD"]


static func id_of(level: int) -> StringName:
	return IDS[clampi(level, 0, IDS.size() - 1)]


static func name_key(level: int) -> StringName:
	return NAME_KEYS[clampi(level, 0, NAME_KEYS.size() - 1)]


## Mức theo id ("easy", "normal", "hard"); id lạ thì trả fallback.
static func from_id(id: StringName, fallback: int = Level.NORMAL) -> int:
	var index: int = IDS.find(id)
	return index if index >= 0 else fallback


## Mức kế tiếp theo vòng Dễ → Trung bình → Khó → Dễ.
static func next(level: int) -> int:
	return (clampi(level, 0, IDS.size() - 1) + 1) % IDS.size()
