shader_type spatial;
// Vệt bọt sau đuôi tàu: hình chữ V loang rộng dần, nhạt dần về phía sau, vỡ vụn theo nhiễu.
// UV.y = 0 ở đuôi tàu, 1 ở cuối vệt; UV.x chạy ngang vệt.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec4 foam_color : source_color = vec4(0.95, 0.98, 1.0, 0.85);

varying vec2 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float across = abs(UV.x - 0.5) * 2.0;
	float spread = mix(0.25, 1.0, UV.y);
	// Hai cánh chữ V và một dải giữa ngắn hơn.
	float arms = 1.0 - smoothstep(0.0, 0.22, abs(across - spread * 0.85));
	float core = (1.0 - smoothstep(0.0, 0.35, across)) * (1.0 - smoothstep(0.0, 0.45, UV.y));
	float n = texture(noise_tex, v_world * 0.35 - vec2(0.0, TIME * 0.2)).r;
	float amount = max(arms, core) * (1.0 - UV.y) * smoothstep(0.3, 0.6, n + 0.15);
	ALBEDO = foam_color.rgb;
	ALPHA = clamp(amount, 0.0, 1.0) * foam_color.a;
}
