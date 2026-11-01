class_name ModelMesh
extends RefCounted
## Lấy mesh từ tệp .glb dựng bằng Blender (tools/blender) trong assets/models/. Mô hình ghi sẵn màu đỉnh nên dùng
## chung vật liệu màu đỉnh của game (một lệnh vẽ cho mọi con cùng loại).

const MODEL_DIR: String = "res://assets/models/"

static var _cache: Dictionary[String, ArrayMesh] = {}


static func path_for(model_name: String) -> String:
	return "%s%s.glb" % [MODEL_DIR, model_name]


static func exists(model_name: String) -> bool:
	return ResourceLoader.exists(path_for(model_name))


## Mesh của mô hình tên model_name (không có .glb), hoặc null nếu chưa có tệp.
static func load_mesh(model_name: String) -> ArrayMesh:
	if _cache.has(model_name):
		return _cache[model_name]
	var path: String = path_for(model_name)
	if not ResourceLoader.exists(path):
		return null
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		return null
	var root: Node = scene.instantiate()
	var found: MeshInstance3D = _first_mesh(root)
	var mesh: ArrayMesh = found.mesh as ArrayMesh if found != null else null
	root.free()
	if mesh != null:
		_cache[model_name] = mesh
	return mesh


static func _first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child: Node in node.get_children():
		var found: MeshInstance3D = _first_mesh(child)
		if found != null:
			return found
	return null
