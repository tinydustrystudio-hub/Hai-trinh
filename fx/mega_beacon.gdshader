shader_type spatial;
// Đèn báo MEGA: vòng LED (COLOR.r = 0) gồm các đoạn sáng quay quanh chân lô cốt, và cột sáng (COLOR.r = 1)
// có vạch quét chạy lên, cao theo phần MEGA còn lại (INSTANCE_CUSTOM.r). Trộn theo độ trong (không cộng sáng)
// để vẫn thấy rõ trên sàn trắng và bọt sóng; không ghi chiều sâu.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 ring_color : source_color = vec4(1.0, 0.8, 0.3, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.95, 0.8, 1.0);
uniform vec4 beam_color : source_color = vec4(1.0, 0.55, 0.12, 1.0);
uniform float ring_segments = 12.0;
uniform float spin_speed = 0.8;

varying float v_kind;
varying float v_left;
varying float v_phase;

void vertex() {
	v_kind = COLOR.r;
	v_left = INSTANCE_CUSTOM.r;
	v_phase = INSTANCE_CUSTOM.g;
}

void fragment() {
	vec3 light;
	float alpha;
	if (v_kind < 0.5) {
		// Vòng LED: đoạn sáng có đuôi mờ, quay đều; viền ngoài sáng hơn.
		float t = fract(UV.x * ring_segments - TIME * spin_speed * ring_segments * 0.25 + v_phase * 7.0);
		float dash = smoothstep(0.0, 0.08, t) * (1.0 - smoothstep(0.45, 0.7, t));
		float edge = 1.0 - abs(UV.y - 0.5) * 2.0;
		float sweep = 0.5 + 0.5 * sin((UV.x + TIME * 0.6 + v_phase) * 6.2831853);
		light = mix(ring_color.rgb, core_color.rgb, dash * (0.3 + sweep * 0.5));
		alpha = (0.25 + dash * 0.75) * smoothstep(0.0, 0.5, edge);
	} else {
		// Cột sáng: mờ dần lên cao, cắt ở phần MEGA còn lại, vạch quét chạy lên.
		float height = UV.y;
		float cut = 1.0 - smoothstep(v_left - 0.04, v_left, height);
		float scan = smoothstep(0.75, 1.0, fract(height * 6.0 - TIME * 2.2 + v_phase));
		float fade = pow(1.0 - height, 1.4);
		light = mix(beam_color.rgb, core_color.rgb, 0.4 + scan * 0.6);
		alpha = (0.35 + scan * 0.5) * fade * cut;
	}
	ALBEDO = light;
	ALPHA = alpha;
}
