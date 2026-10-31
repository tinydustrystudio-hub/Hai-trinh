shader_type spatial;
// Nước bản 2 (GDD mục 8.6, góp ý 3 của đạo diễn): xanh chàm đậm, sóng Gerstner nhẹ ở vertex shader với tối đa
// sáu lớp lệch hướng, bước sóng lẻ nhau và biên độ nhấp nhô dọc theo ngọn sóng (không còn vệt chéo đều);
// hai lớp normal map cuộn ngược chiều; phản chiếu bầu trời theo góc nhìn, có mây trôi phản chiếu thành những
// mảng sáng ngẫu nhiên khắp mặt biển; lấp lánh lóe ngẫu nhiên khắp nơi. Vệt sáng mềm sau đảo chính chỉ còn
// rất nhẹ. Ánh sáng của nước tách khỏi hướng nắng chiếu công trình.
// Tự tính ánh sáng (unshaded) cho rẻ: mặt nước phủ kín màn hình nên mỗi phép tính đều đắt.
render_mode unshaded, shadows_disabled, cull_back;

uniform vec4 deep_color : source_color = vec4(0.02, 0.07, 0.2, 1.0);
uniform vec4 crest_color : source_color = vec4(0.05, 0.2, 0.38, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.06, 0.32, 0.45, 1.0);
uniform vec4 sky_horizon : source_color = vec4(0.72, 0.84, 0.95, 1.0);
uniform vec4 sky_zenith : source_color = vec4(0.3, 0.52, 0.85, 1.0);
uniform vec4 cloud_color : source_color = vec4(0.86, 0.91, 0.97, 1.0);
uniform vec4 sun_color : source_color = vec4(1.0, 0.9, 0.72, 1.0);
// Vệt sáng của nước: tâm (x, z), bán kính theo x và theo z, độ sáng.
uniform vec2 highlight_center = vec2(0.0, -34.0);
uniform vec2 highlight_size = vec2(31.0, 18.0);
uniform float highlight_strength = 0.35;
uniform vec4 highlight_color : source_color = vec4(0.75, 0.82, 0.9, 1.0);
uniform float sparkle_strength = 0.75;
uniform sampler2D normal_a : hint_normal, repeat_enable, filter_linear_mipmap;
uniform sampler2D normal_b : hint_normal, repeat_enable, filter_linear_mipmap;
// Nhiễu dùng làm mây trên trời (chỉ thấy qua phản chiếu).
uniform sampler2D cloud_tex : repeat_enable, filter_linear_mipmap;
uniform float normal_scale_a = 0.07;
uniform float normal_scale_b = 0.19;
uniform vec2 scroll_a = vec2(0.012, 0.008);
uniform vec2 scroll_b = vec2(-0.011, 0.013);
uniform float normal_strength = 0.45;
// Phần trời phản chiếu tối thiểu (nhìn gần thẳng xuống, Fresnel thật gần như bằng 0).
uniform float sky_reflection = 0.16;
// Mây: cỡ mảng (nghịch đảo đơn vị Godot), tốc độ trôi, độ sáng.
uniform float cloud_scale = 0.0045;
uniform vec2 cloud_drift = vec2(0.0035, 0.0012);
uniform float cloud_strength = 0.11;
// Mỗi sóng: x, y = hướng; z = độ dốc; w = bước sóng. wave_shapes: pha, tỉ lệ tần số dọc ngọn, tốc độ, độ sâu.
uniform vec4 waves[6];
uniform vec4 wave_shapes[6];
// Chuyển động riêng: hệ số tốc độ, tần số, tốc độ trôi và độ sâu của đợt sóng lớn (lúc to lúc nhỏ theo vùng).
uniform vec4 wave_motions[6];
uniform int wave_count : hint_range(0, 6) = 6;
uniform float gravity = 9.8;
// 1 = đủ chi tiết (hai lớp normal map, mây hai lớp, lấp lánh); 0 = rẻ.
uniform int detail : hint_range(0, 1) = 1;
// Vùng nước sáng quanh đảo chính: x, y = tâm; z = bán kính; w = độ loang.
uniform vec4 island_glow = vec4(0.0, 0.0, 14.0, 9.0);

varying vec3 v_world;
varying vec3 v_normal;
varying float v_height;

vec3 gerstner(vec4 wave, vec4 shape, vec4 motion, vec3 p, float t, inout vec3 tangent, inout vec3 binormal) {
	float k = 6.2831853 / wave.w;
	float c = sqrt(gravity / k) * motion.x;
	vec2 d = normalize(wave.xy);
	// Biên độ nhấp nhô dọc theo ngọn sóng (cùng công thức với Ocean.crest_modulation).
	float along = -d.y * p.x + d.x * p.z;
	float swell = 1.0 + motion.w * sin((p.x * 0.78 + p.z * 0.62) * motion.y + t * motion.z + shape.x * 1.7);
	float steepness = wave.z * swell * (1.0 + shape.w * sin(along * k * shape.y + t * shape.z + shape.x));
	float f = k * (dot(d, p.xz) - c * t);
	float a = steepness / k;
	float s = sin(f);
	float co = cos(f);
	tangent += vec3(-d.x * d.x * steepness * s, d.x * steepness * co, -d.x * d.y * steepness * s);
	binormal += vec3(-d.x * d.y * steepness * s, d.y * steepness * co, -d.y * d.y * steepness * s);
	return vec3(d.x * a * co, a * s, d.y * a * co);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 tangent = vec3(1.0, 0.0, 0.0);
	vec3 binormal = vec3(0.0, 0.0, 1.0);
	vec3 offset = vec3(0.0);
	for (int i = 0; i < 6; i++) {
		if (i >= wave_count) {
			break;
		}
		offset += gerstner(waves[i], wave_shapes[i], wave_motions[i], world, TIME, tangent, binormal);
	}
	VERTEX += offset;
	v_world = world + offset;
	v_normal = normalize(cross(binormal, tangent));
	v_height = offset.y;
}

void fragment() {
	// Normal map cuộn: kênh x, y của map là độ nghiêng theo x, z của mặt nước.
	vec2 na = texture(normal_a, v_world.xz * normal_scale_a + TIME * scroll_a).xy * 2.0 - 1.0;
	vec2 tilt = na;
	if (detail > 0) {
		vec2 nb = texture(normal_b, v_world.xz * normal_scale_b + TIME * scroll_b).xy * 2.0 - 1.0;
		tilt = (na + nb) * 0.6;
	}
	vec3 n = normalize(v_normal + vec3(tilt.x, 0.0, tilt.y) * normal_strength);
	vec3 view = normalize(CAMERA_POSITION_WORLD - v_world);

	float h = clamp(v_height * 1.8 + 0.5, 0.0, 1.0);
	vec3 water = mix(deep_color.rgb, crest_color.rgb, h);
	float near_island = 1.0 - smoothstep(island_glow.z, island_glow.z + island_glow.w, distance(v_world.xz, island_glow.xy));
	water = mix(water, shallow_color.rgb, near_island * 0.55);

	// Phản chiếu trời theo góc nhìn (Fresnel Schlick, nước ~2%).
	float facing = clamp(dot(n, view), 0.0, 1.0);
	float fresnel = 0.02 + 0.98 * pow(1.0 - facing, 5.0);
	vec3 reflected = reflect(-view, n);
	vec3 sky = mix(sky_horizon.rgb, sky_zenith.rgb, clamp(reflected.y, 0.0, 1.0));
	vec3 color = mix(water, sky * 0.75, clamp(sky_reflection + fresnel * 1.4, 0.0, 0.85));

	// Mây trôi phản chiếu: lấy mẫu "trời" theo tia phản xạ nên mảng sáng gợn theo sóng, nằm rải khắp biển
	// và trôi chậm, không cố định ở một chỗ.
	vec2 sky_point = v_world.xz + reflected.xz / max(reflected.y, 0.25) * 18.0;
	float cloud = texture(cloud_tex, sky_point * cloud_scale + TIME * cloud_drift).r;
	if (detail > 0) {
		cloud = cloud * 0.6 + texture(cloud_tex, sky_point * cloud_scale * 2.3 - TIME * cloud_drift * 1.7).r * 0.4;
	}
	cloud = smoothstep(0.52, 0.8, cloud);
	color += cloud_color.rgb * cloud * (cloud_strength + fresnel * 0.6);

	// Vệt sáng mềm rất nhẹ sau đảo theo hướng nhìn.
	vec3 to_camera = normalize(CAMERA_POSITION_WORLD - vec3(highlight_center.x, 0.0, highlight_center.y));
	vec3 water_light = vec3(-to_camera.x, to_camera.y, -to_camera.z);
	vec2 offset = (v_world.xz - highlight_center) / highlight_size;
	float area = exp(-dot(offset, offset));
	float sheen = pow(max(dot(reflected, water_light), 0.0), 20.0);
	color += mix(highlight_color.rgb, sun_color.rgb, 0.4) * area * (0.07 + sheen * 0.3) * highlight_strength;

	// Lấp lánh: mỗi ô nhỏ lóe lên ở một thời điểm ngẫu nhiên rồi tắt, ô nào lóe đổi theo từng nhịp,
	// nên điểm sáng rải khắp biển mà không lặp lại thành hàng.
	if (detail > 0) {
		vec2 cell = floor(v_world.xz * 2.2);
		float offset_t = hash(cell + 7.31);
		float beat = TIME * (0.35 + offset_t * 0.3) + offset_t * 13.0;
		float epoch = floor(beat);
		float chosen = step(0.955, hash(cell + epoch * 1.618));
		float life = fract(beat);
		float blink = smoothstep(0.0, 0.08, life) * (1.0 - smoothstep(0.12, 0.3, life));
		float facet = smoothstep(0.25, 0.7, length(tilt)) * (0.6 + 0.4 * h);
		color += mix(sun_color.rgb, vec3(1.0), 0.3) * chosen * blink * facet * sparkle_strength;
	}
	ALBEDO = color;
}
