shader_type spatial;
// Mưa 3D: mỗi hạt là một nét mảnh thẳng đứng rơi từ trời xuống mặt biển trong không gian trận, nên bị đảo và công
// trình che đúng chỗ, và chạm mặt biển ở nơi có gợn nước. Hoàn toàn trên GPU: vị trí rơi tính từ TIME.
// Mỗi hạt: INSTANCE_CUSTOM.r = pha ngẫu nhiên, .g = hệ số tốc độ, .b = ngưỡng hiện (mưa nhẹ chỉ hiện hạt có ngưỡng thấp).
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float fall_height = 16.0;
uniform float streak_length = 1.5;
// Tốc độ rơi (đơn vị Godot mỗi giây): chậm vừa phải, nét mưa vẫn thấy rõ hướng rơi.
uniform float fall_speed = 7.0;
// Gió làm nét mưa xiên: dịch ngang theo độ cao, x và z.
uniform vec2 slant = vec2(0.12, 0.0);
uniform vec4 rain_color : source_color = vec4(0.78, 0.87, 0.96, 1.0);

varying float v_alpha;

void vertex() {
	float phase = INSTANCE_CUSTOM.r;
	float speed = fall_speed * (0.8 + INSTANCE_CUSTOM.g * 0.5);
	// t chạy 0 → 1 trong lúc rơi; cao độ giảm dần từ fall_height xuống 0 rồi quay lại.
	float t = fract(TIME * speed / fall_height + phase);
	float y = (1.0 - t) * fall_height;
	// along: 0 ở đầu nét (thấp nhất, sáng), 1 ở đuôi nét (cao hơn, mờ).
	float along = clamp(VERTEX.y / streak_length, 0.0, 1.0);
	vec3 world_offset = vec3(slant.x * y, y + along * streak_length, slant.y * y);
	VERTEX = vec3(VERTEX.x, 0.0, 0.0) + world_offset;
	float shown = step(INSTANCE_CUSTOM.b, intensity);
	// Mờ dần gần mặt biển và gần đỉnh; đuôi nét mờ hơn đầu.
	v_alpha = shown * smoothstep(0.0, 0.8, y) * smoothstep(fall_height, fall_height * 0.8, y) * (0.25 + 0.75 * (1.0 - along));
}

void fragment() {
	ALBEDO = rain_color.rgb;
	ALPHA = v_alpha * 0.55;
}
