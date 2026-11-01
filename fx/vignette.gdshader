shader_type canvas_item;
// Tối viền màn hình: rẻ (một lượt vẽ, không đọc lại khung hình), chỉ pha màu vào mép.
uniform vec4 tint : source_color = vec4(0.0, 0.03, 0.08, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.2;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = dot(p, p) * 0.5;
	float edge = smoothstep(0.35, 1.0, d);
	COLOR = vec4(tint.rgb, edge * strength);
}
