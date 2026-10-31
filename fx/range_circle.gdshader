shader_type spatial;
// Vòng tầm bắn: mặt phẳng đơn vị (bán kính 1) co giãn theo tầm; lòng vòng mờ, viền cam rõ, có nhịp nhẹ.
// Hiện trên mặt nước và đảo, không ghi chiều sâu.
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled;

uniform vec4 fill_color : source_color = vec4(1.0, 0.62, 0.2, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.85, 0.5, 1.0);
// Độ rộng viền theo đơn vị Godot; radius_units = tầm thật, để viền dày đều dù tầm lớn hay nhỏ.
uniform float radius_units = 10.0;
uniform float edge_width = 0.45;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float edge = smoothstep(1.0 - edge_width / radius_units * 2.0, 1.0 - edge_width / radius_units, r) * (1.0 - smoothstep(0.995, 1.0, r));
	float inside = 1.0 - smoothstep(0.985, 1.0, r);
	float pulse = 0.85 + 0.15 * sin(TIME * 3.0);
	float fill = inside * 0.14;
	ALBEDO = mix(fill_color.rgb, edge_color.rgb, edge);
	ALPHA = max(fill, edge * 0.85 * pulse);
}
