shader_type spatial;
// Dải luồng địch: nền mờ, viền sáng hơn, vạch hình mũi tên chạy về phía đảo.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 base_color : source_color = vec4(1.0, 0.78, 0.5, 0.1);
uniform vec4 edge_color : source_color = vec4(1.0, 0.75, 0.4, 0.7);
uniform vec4 chevron_color : source_color = vec4(1.0, 0.92, 0.75, 0.55);
uniform float chevron_spacing = 3.0;
uniform float scroll_speed = 2.0;

void fragment() {
	float across = abs(UV.x - 0.5) * 2.0;
	// Vạch chữ V: lệch theo khoảng cách tới tâm dải, cuộn dần về đầu cuối luồng.
	float phase = fract((UV.y + across * 0.6 + TIME * scroll_speed) / chevron_spacing);
	float chevron = step(phase, 0.22) * step(across, 0.8);
	float edge = smoothstep(0.8, 0.95, across);
	vec4 color = mix(base_color, chevron_color, chevron);
	color = mix(color, edge_color, edge);
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
