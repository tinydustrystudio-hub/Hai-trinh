shader_type spatial;
// Nước bản 2 (GDD mục 8.6): xanh chàm đậm, sóng Gerstner nhẹ ở vertex shader, hai lớp normal map cuộn,
// phản chiếu bầu trời theo góc nhìn, điểm lấp lánh của nắng, sáng hơn sát chân đảo.
// Tự tính ánh sáng (unshaded) cho rẻ: mặt nước phủ kín màn hình nên mỗi phép tính đều đắt.
render_mode unshaded, shadows_disabled, cull_back;

uniform vec4 deep_color : source_color = vec4(0.02, 0.07, 0.2, 1.0);
uniform vec4 crest_color : source_color = vec4(0.05, 0.2, 0.38, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.06, 0.32, 0.45, 1.0);
uniform vec4 sky_horizon : source_color = vec4(0.72, 0.84, 0.95, 1.0);
uniform vec4 sky_zenith : source_color = vec4(0.3, 0.52, 0.85, 1.0);
uniform vec4 sun_color : source_color = vec4(1.0, 0.9, 0.72, 1.0);
// Hướng từ mặt nước tới mặt trời (đã chuẩn hóa).
uniform vec3 sun_direction = vec3(0.45, 0.6, -0.65);
uniform sampler2D normal_a : hint_normal, repeat_enable, filter_linear_mipmap;
uniform sampler2D normal_b : hint_normal, repeat_enable, filter_linear_mipmap;
uniform float normal_scale_a = 0.045;
uniform float normal_scale_b = 0.11;
uniform vec2 scroll_a = vec2(0.012, 0.008);
uniform vec2 scroll_b = vec2(-0.009, 0.014);
uniform float normal_strength = 0.55;
// Mỗi sóng: x, y = hướng; z = độ dốc; w = bước sóng.
uniform vec4 wave_a = vec4(1.0, 0.4, 0.04, 24.0);
uniform vec4 wave_b = vec4(-0.3, 1.0, 0.03, 14.0);
uniform vec4 wave_c = vec4(0.7, -0.6, 0.025, 8.0);
uniform int wave_count : hint_range(0, 3) = 3;
uniform float gravity = 9.8;
// 1 = đủ chi tiết (hai lớp normal map, lấp lánh); 0 = rẻ.
uniform int detail : hint_range(0, 1) = 1;
// Vùng nước sáng quanh đảo chính: x, y = tâm; z = bán kính; w = độ loang.
uniform vec4 island_glow = vec4(0.0, 0.0, 14.0, 9.0);

varying vec3 v_world;
varying vec3 v_normal;
varying float v_height;

vec3 gerstner(vec4 wave, vec3 p, float t, inout vec3 tangent, inout vec3 binormal) {
	float steepness = wave.z;
	float k = 6.2831853 / wave.w;
	float c = sqrt(gravity / k);
	vec2 d = normalize(wave.xy);
	float f = k * (dot(d, p.xz) - c * t);
	float a = steepness / k;
	float s = sin(f);
	float co = cos(f);
	tangent += vec3(-d.x * d.x * steepness * s, d.x * steepness * co, -d.x * d.y * steepness * s);
	binormal += vec3(-d.x * d.y * steepness * s, d.y * steepness * co, -d.y * d.y * steepness * s);
	return vec3(d.x * a * co, a * s, d.y * a * co);
}

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 tangent = vec3(1.0, 0.0, 0.0);
	vec3 binormal = vec3(0.0, 0.0, 1.0);
	vec3 offset = vec3(0.0);
	if (wave_count > 0) offset += gerstner(wave_a, world, TIME, tangent, binormal);
	if (wave_count > 1) offset += gerstner(wave_b, world, TIME, tangent, binormal);
	if (wave_count > 2) offset += gerstner(wave_c, world, TIME, tangent, binormal);
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
	vec3 sun = normalize(sun_direction);

	float h = clamp(v_height * 2.5 + 0.5, 0.0, 1.0);
	vec3 water = mix(deep_color.rgb, crest_color.rgb, h);
	float near_island = 1.0 - smoothstep(island_glow.z, island_glow.z + island_glow.w, distance(v_world.xz, island_glow.xy));
	water = mix(water, shallow_color.rgb, near_island * 0.55);
	// Nắng ấm khuếch tán nhẹ trên mặt nước.
	water *= 0.8 + 0.35 * max(dot(n, sun), 0.0) * sun_color.rgb;

	// Phản chiếu trời theo góc nhìn (Fresnel Schlick, nước ~2%).
	float facing = clamp(dot(n, view), 0.0, 1.0);
	float fresnel = 0.02 + 0.98 * pow(1.0 - facing, 5.0);
	vec3 reflected = reflect(-view, n);
	vec3 sky = mix(sky_horizon.rgb, sky_zenith.rgb, clamp(reflected.y, 0.0, 1.0));
	vec3 color = mix(water, sky, clamp(fresnel * 1.4, 0.0, 0.85));

	// Lấp lánh của nắng.
	if (detail > 0) {
		float glint = pow(max(dot(reflected, sun), 0.0), 350.0);
		float sparkle = step(0.82, fract(sin(dot(floor(v_world.xz * 3.0), vec2(12.9898, 78.233))) * 43758.5453 + TIME * 0.7));
		color += sun_color.rgb * (glint * 3.0 + glint * sparkle * 4.0);
	}
	ALBEDO = color;
}
