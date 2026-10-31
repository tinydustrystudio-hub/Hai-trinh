shader_type spatial;
// Vệt sáng của đèn báo trên mặt nước: quạt sáng đỏ cam mờ dần ra xa, có các vạch sóng chạy ra phía địch sẽ tới.
// Số thứ tự đèn nằm trong kênh đỏ của màu đỉnh (LaneBeacons.index_tag); đèn tắt thì phần quạt đó trong suốt.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 active_flags = vec4(0.0);
uniform vec4 beam_color : source_color = vec4(1.0, 0.36, 0.14, 1.0);
uniform float beam_length = 26.0;
uniform float strength = 0.9;
uniform float pulse_speed = 9.0;
uniform float pulse_spacing = 6.0;

varying float v_active;

void vertex() {
	int index = clamp(int(COLOR.r * 4.0), 0, 3);
	v_active = active_flags[index];
}

void fragment() {
	// UV.y nội suy tuyến tính theo tam giác quạt: tỉ lệ khoảng cách từ gốc.
	float along = UV.y;
	float across = abs(UV.x - 0.5) * 2.0;
	float fade = pow(1.0 - along, 1.3) * (1.0 - smoothstep(0.55, 1.0, across));
	float distance = along * beam_length;
	float pulse = fract((distance - TIME * pulse_speed) / pulse_spacing);
	float band = smoothstep(0.0, 0.15, pulse) * (1.0 - smoothstep(0.3, 0.5, pulse));
	float light = fade * (0.35 + band * 0.9) * strength * v_active;
	ALBEDO = beam_color.rgb * light;
}
