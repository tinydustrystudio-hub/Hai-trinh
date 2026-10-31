shader_type spatial;
// Nước bản 2 (GDD mục 8.6): xanh chàm đậm, sóng Gerstner nhẹ ở vertex shader, hai lớp normal map cuộn,
// phản chiếu bầu trời theo góc nhìn, sáng hơn sát chân đảo; một vệt sáng mềm, rộng phía sau đảo chính theo
// hướng nhìn của camera và lấp lánh nhẹ rải đều khắp mặt nước. Vệt sáng của nước tách khỏi hướng nắng
// chiếu công trình, để không dồn về một góc màn hình.
// Tự tính ánh sáng (unshaded) cho rẻ: mặt nước phủ kín màn hình nên mỗi phép tính đều đắt.
render_mode unshaded, shadows_disabled, cull_back;

uniform vec4 deep_color : source_color = vec4(0.02, 0.07, 0.2, 1.0);
uniform vec4 crest_color : source_color = vec4(0.05, 0.2, 0.38, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.06, 0.32, 0.45, 1.0);
uniform vec4 sky_horizon : source_color = vec4(0.72, 0.84, 0.95, 1.0);
uniform vec4 sky_zenith : source_color = vec4(0.3, 0.52, 0.85, 1.0);
uniform vec4 sun_color : source_color = vec4(1.0, 0.9, 0.72, 1.0);
// Vệt sáng của nước: tâm (x, z), bán kính theo x và theo z, độ sáng.
uniform vec2 highlight_center = vec2(0.0, -34.0);
uniform vec2 highlight_size = vec2(31.0, 18.0);
uniform float highlight_strength = 1.0;
uniform float sparkle_strength = 0.6;
uniform sampler2D normal_a : hint_normal, repeat_enable, filter_linear_mipmap;
uniform sampler2D normal_b : hint_normal, repeat_enable, filter_linear_mipmap;
uniform float normal_scale_a = 0.07;
uniform float normal_scale_b = 0.19;
uniform vec2 scroll_a = vec2(0.012, 0.008);
uniform vec2 scroll_b = vec2(-0.009, 0.014);
uniform float normal_strength = 0.45;
// Phần trời phản chiếu tối thiểu (nhìn gần thẳng xuống, Fresnel thật gần như bằng 0).
uniform float sky_reflection = 0.16;
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

	float h = clamp(v_height * 2.5 + 0.5, 0.0, 1.0);
	vec3 water = mix(deep_color.rgb, crest_color.rgb, h);
	float near_island = 1.0 - smoothstep(island_glow.z, island_glow.z + island_glow.w, distance(v_world.xz, island_glow.xy));
	water = mix(water, shallow_color.rgb, near_island * 0.55);

	// Phản chiếu trời theo góc nhìn (Fresnel Schlick, nước ~2%).
	float facing = clamp(dot(n, view), 0.0, 1.0);
	float fresnel = 0.02 + 0.98 * pow(1.0 - facing, 5.0);
	vec3 reflected = reflect(-view, n);
	vec3 sky = mix(sky_horizon.rgb, sky_zenith.rgb, clamp(reflected.y, 0.0, 1.0));
	vec3 color = mix(water, sky * 0.75, clamp(sky_reflection + fresnel * 1.4, 0.0, 0.85));

	// Vệt sáng mềm: phản chiếu một "mặt trời của nước" đặt sao cho tia phản xạ rơi đúng tâm vệt,
	// nên vệt luôn nằm phía sau đảo theo hướng nhìn; sóng và normal map làm vệt gợn nhẹ.
	vec3 to_camera = normalize(CAMERA_POSITION_WORLD - vec3(highlight_center.x, 0.0, highlight_center.y));
	vec3 water_light = vec3(-to_camera.x, to_camera.y, -to_camera.z);
	vec2 offset = (v_world.xz - highlight_center) / highlight_size;
	float area = exp(-dot(offset, offset));
	float sheen = pow(max(dot(reflected, water_light), 0.0), 12.0);
	color += sun_color.rgb * area * (0.22 + sheen * 0.8) * highlight_strength;

	// Lấp lánh nhẹ rải đều: mỗi ô nhỏ một nhịp nháy riêng, chỉ trên mặt sóng nghiêng.
	if (detail > 0) {
		vec2 cell = floor(v_world.xz * 2.5 + vec2(TIME * 0.25, 0.0));
		float seed = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
		float blink = pow(max(sin(TIME * (2.0 + seed * 3.0) + seed * 6.2831853), 0.0), 6.0);
		float facet = smoothstep(0.3, 0.75, length(tilt));
		color += sun_color.rgb * step(0.93, seed) * blink * facet * sparkle_strength;
	}
	ALBEDO = color;
}
