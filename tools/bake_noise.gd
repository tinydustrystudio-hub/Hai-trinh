extends SceneTree
## Dựng sẵn ba texture nhiễu của nước thành ảnh PNG (chạy khi đổi thông số nhiễu trong Ocean.NOISE_SPECS):
##   godot --headless -s tools/bake_noise.gd
## rồi `godot --headless --import` và commit các file assets/textures/*.png cùng .import.
## Có vòng lặp này để vào trận không phải sinh nhiễu (tốn hàng trăm mili giây trên điện thoại).


func _initialize() -> void:
	for spec: Dictionary in Ocean.NOISE_SPECS:
		var texture: NoiseTexture2D = Ocean.make_noise_texture(spec["seed"], spec["frequency"], spec["normal"])
		await texture.changed
		var path: String = "res://assets/textures/%s.png" % spec["name"]
		var error: Error = texture.get_image().save_png(path)
		print("bake ", path, " -> ", error_string(error))
	quit()
