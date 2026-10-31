shader_type spatial;
// Đầu đèn báo hướng địch: kính tối khi tắt; khi bật thì nháy đỏ cam hai nhịp mỗi giây, có viền sáng.
// Số thứ tự đèn nằm trong kênh đỏ của màu đỉnh (LaneBeacons.index_tag).
render_mode unshaded, shadows_disabled;

uniform vec4 active_flags = vec4(0.0);
uniform vec4 off_color : source_color = vec4(0.22, 0.08, 0.06, 1.0);
uniform vec4 on_color : source_color = vec4(1.0, 0.32, 0.12, 1.0);
uniform vec4 flash_color : source_color = vec4(1.0, 0.85, 0.6, 1.0);
uniform float blink_rate = 2.0;

varying float v_active;

void vertex() {
	int index = clamp(int(COLOR.r * 4.0), 0, 3);
	v_active = active_flags[index];
}

void fragment() {
	// Nháy dứt khoát (đèn LED), có chút sáng dư giữa hai nhịp.
	float phase = fract(TIME * blink_rate);
	float flash = smoothstep(0.0, 0.05, phase) * (1.0 - smoothstep(0.35, 0.45, phase));
	vec3 lit = mix(on_color.rgb * 0.45, mix(on_color.rgb, flash_color.rgb, 0.35) * 1.6, flash);
	ALBEDO = mix(off_color.rgb, lit, v_active);
}
