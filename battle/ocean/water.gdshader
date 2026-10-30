shader_type spatial;
// Nước bản 1: tối đa 3 lớp sóng Gerstner ở vertex shader, màu theo độ cao sóng, bọt trên đỉnh,
// viền sáng theo góc nhìn. Không dùng texture, không phản chiếu màn hình (GL Compatibility).
render_mode specular_schlick_ggx, shadows_disabled;

uniform vec4 deep_color : source_color = vec4(0.0, 0.36, 0.48, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.12, 0.72, 0.74, 1.0);
uniform vec4 foam_color : source_color = vec4(0.92, 0.98, 1.0, 1.0);
uniform vec4 sky_color : source_color = vec4(0.72, 0.9, 1.0, 1.0);
// Mỗi sóng: x, y = hướng (trên mặt x–z); z = độ dốc; w = bước sóng.
uniform vec4 wave_a = vec4(1.0, 0.4, 0.07, 22.0);
uniform vec4 wave_b = vec4(-0.3, 1.0, 0.05, 13.0);
uniform vec4 wave_c = vec4(0.7, -0.6, 0.04, 7.0);
uniform int wave_count : hint_range(0, 3) = 3;
uniform float gravity = 9.8;
uniform float foam_threshold = 0.28;

varying float v_height;
varying vec2 v_world_xz;

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
	NORMAL = normalize(cross(binormal, tangent));
	v_height = offset.y;
	v_world_xz = world.xz;
}

void fragment() {
	float h = clamp(v_height * 1.3 + 0.45, 0.0, 1.0);
	vec3 color = mix(deep_color.rgb, shallow_color.rgb, h);
	// Gợn nhỏ rẻ tiền để mặt nước không phẳng lì.
	float ripple = sin(v_world_xz.x * 1.7 + TIME * 1.3) * sin(v_world_xz.y * 1.9 - TIME * 1.1);
	float foam = smoothstep(foam_threshold, foam_threshold + 0.12, v_height + ripple * 0.04);
	color = mix(color, foam_color.rgb, foam * 0.45);
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	color = mix(color, sky_color.rgb, fresnel * 0.5);
	ALBEDO = color;
	ROUGHNESS = 0.12;
	SPECULAR = 0.6;
	METALLIC = 0.0;
}
