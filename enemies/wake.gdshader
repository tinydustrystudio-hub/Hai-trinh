shader_type spatial;
// Vệt bọt sau đuôi tàu: một mảnh chia nhỏ theo chiều dài, vertex shader uốn mảnh theo độ cong của
// đường tàu đã đi (EnemyPool.wake_point dùng cùng công thức), nên vệt cong mềm khi tàu đổi hướng.
// INSTANCE_CUSTOM: x = độ cong, y = bề ngang, z = chiều dài vệt. Gốc ở đuôi tàu, +z về phía sau.
// Hình chữ V loang rộng dần, mép mềm, nhạt dần về phía sau, vỡ vụn theo nhiễu cuộn.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec4 foam_color : source_color = vec4(0.95, 0.98, 1.0, 0.8);

varying vec2 v_world;
varying float v_along;

void vertex() {
	float curvature = INSTANCE_CUSTOM.x;
	// PlaneMesh: UV.y = 0 ở mép −z (đuôi tàu), 1 ở mép +z (cuối vệt).
	float s = UV.y * INSTANCE_CUSTOM.z;
	float x = VERTEX.x * INSTANCE_CUSTOM.y;
	float theta = curvature * s;
	vec3 center;
	if (abs(curvature) < 0.0001) {
		center = vec3(0.5 * curvature * s * s, 0.0, s);
	} else {
		center = vec3((1.0 - cos(theta)) / curvature, 0.0, sin(theta) / curvature);
	}
	VERTEX = center + vec3(cos(theta), 0.0, -sin(theta)) * x;
	v_along = UV.y;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float v = clamp(v_along, 0.0, 1.0);
	float across = abs(UV.x - 0.5) * 2.0;
	float spread = mix(0.15, 0.9, sqrt(v));
	float arm_width = mix(0.1, 0.24, v);
	float arms = exp(-pow((across - spread) / arm_width, 2.0));
	float core = exp(-pow(across / mix(0.18, 0.4, v), 2.0)) * (1.0 - v) * (1.0 - v);
	float n = texture(noise_tex, v_world * 0.3 - vec2(0.0, TIME * 0.15)).r;
	float fade = pow(1.0 - v, 1.4) * smoothstep(0.0, 0.08, v);
	float amount = (arms * 0.85 + core) * fade * (0.45 + 0.75 * n);
	ALBEDO = foam_color.rgb;
	ALPHA = clamp(amount, 0.0, 1.0) * foam_color.a;
}
