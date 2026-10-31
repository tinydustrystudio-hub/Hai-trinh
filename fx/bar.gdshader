shader_type spatial;
// Thanh trạng thái nổi (máu địch, Quá tải lô cốt): một mảnh cho cả nền lẫn phần đầy.
// COLOR = màu phần đầy; INSTANCE_CUSTOM.x = tỉ lệ đầy (0–1).
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled;

uniform vec4 back_color : source_color = vec4(0.05, 0.08, 0.12, 0.8);
// Viền nền quanh phần đầy, theo tỉ lệ chiều cao.
uniform float border = 0.18;

varying vec4 v_fill_color;
varying float v_fill;

void vertex() {
	v_fill_color = COLOR;
	v_fill = INSTANCE_CUSTOM.x;
}

void fragment() {
	float inside_y = step(border, UV.y) * step(UV.y, 1.0 - border);
	float filled = step(UV.x, v_fill) * inside_y;
	vec4 color = mix(back_color, vec4(v_fill_color.rgb, 1.0), filled);
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
