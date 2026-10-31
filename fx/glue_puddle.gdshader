shader_type spatial;
// Vũng keo rong biển trên mặt nước: vòng tròn mép gợn theo nhiễu, vàng lục, sáng ở viền, nhạt dần khi hết hạn.
// COLOR.a của từng vũng (MultiMesh) là phần thời gian còn lại.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec4 glue_color : source_color = vec4(0.62, 0.78, 0.2, 0.75);
uniform vec4 rim_color : source_color = vec4(0.88, 0.95, 0.45, 0.9);

varying vec2 v_world;
varying float v_life;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	v_life = COLOR.a;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float n = texture(noise_tex, v_world * 0.25 + vec2(TIME * 0.02)).r;
	float r = length(p) + (n - 0.5) * 0.35;
	float body = 1.0 - smoothstep(0.75, 0.95, r);
	float rim = smoothstep(0.6, 0.85, r) * body;
	vec4 color = mix(glue_color, rim_color, rim);
	float fade = smoothstep(0.0, 0.35, v_life);
	ALBEDO = color.rgb;
	ALPHA = body * color.a * fade;
}
