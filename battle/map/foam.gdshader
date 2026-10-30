shader_type spatial;
// Bọt trắng quanh chân đảo: đậm sát mép, loang ra ngoài theo nhịp sóng, vỡ vụn theo nhiễu cuộn.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec4 foam_color : source_color = vec4(0.95, 0.98, 1.0, 0.9);

varying vec2 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float n1 = texture(noise_tex, v_world * 0.09 + vec2(TIME * 0.015, TIME * 0.01)).r;
	float n2 = texture(noise_tex, v_world * 0.23 - vec2(TIME * 0.02, -TIME * 0.025)).r;
	float shore = 1.0 - UV.x;
	// Gợn bọt chạy từ mép đảo ra ngoài.
	float ripple = 0.5 + 0.5 * sin(UV.x * 11.0 - TIME * 1.6 + n1 * 5.0);
	float amount = shore * shore * 1.3 + ripple * shore * 0.55;
	amount *= smoothstep(0.32, 0.62, n1 * 0.55 + n2 * 0.6);
	ALBEDO = foam_color.rgb;
	ALPHA = clamp(amount, 0.0, 1.0) * foam_color.a;
}
