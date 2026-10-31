shader_type spatial;
// Vòng sáng cam bung ra khi kích MEGA. COLOR.r = tiến độ (0–1), COLOR.g = 1 cho vòng đầy đủ, 0 cho bản nhẹ.
render_mode unshaded, blend_add, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled;

uniform vec4 burst_color : source_color = vec4(1.0, 0.55, 0.15, 1.0);

varying float v_progress;
varying float v_full;

void vertex() {
	v_progress = COLOR.r;
	v_full = COLOR.g;
}

void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float ring = smoothstep(0.62, 0.88, r) * (1.0 - smoothstep(0.9, 1.0, r));
	float fill = (1.0 - smoothstep(0.0, 0.9, r)) * 0.25 * v_full;
	float fade = 1.0 - v_progress;
	float strength = mix(0.5, 2.2, v_full);
	ALBEDO = burst_color.rgb * (ring + fill) * fade * strength;
}
