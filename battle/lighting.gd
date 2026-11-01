class_name Lighting
extends RefCounted
## Áp ánh sáng của màn (LightingData) vào nắng, môi trường, biển và viền tối (P6).

const PATHS: Dictionary[StringName, String] = {
	&"day": "res://data/lighting/day.tres",
	&"dawn": "res://data/lighting/dawn.tres",
	&"dusk": "res://data/lighting/dusk.tres",
}
const ORDER: Array[StringName] = [&"day", &"dawn", &"dusk"]


## Ánh sáng theo id; id lạ thì ban ngày. Nạp lúc chạy (cùng lý do với Weather.by_id).
static func by_id(id: StringName) -> LightingData:
	return load(PATHS.get(id, PATHS[&"day"]))


static func apply(data: LightingData, environment: Environment, sun: DirectionalLight3D, ocean: Ocean, vignette: Vignette) -> void:
	if sun != null:
		sun.light_color = data.sun_color
		sun.light_energy = data.sun_energy
	if environment != null:
		environment.ambient_light_color = data.ambient_color
		environment.ambient_light_energy = data.ambient_energy
		environment.background_color = data.background_color
		environment.adjustment_enabled = true
		environment.adjustment_contrast = data.contrast
		environment.adjustment_saturation = data.saturation
		environment.adjustment_brightness = data.brightness
		environment.glow_intensity = data.glow_intensity
		environment.glow_hdr_threshold = data.glow_threshold
	if ocean != null:
		ocean.set_palette(data)
	if vignette != null:
		vignette.set_look(data.vignette, data.vignette_color)
