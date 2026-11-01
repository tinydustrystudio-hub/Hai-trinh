shader_type canvas_item;
// Màn mưa nhẹ, mảnh và rơi chậm: ba lớp vệt mưa xiên theo gió; lớp gần thưa, to và nhanh hơn một chút, lớp xa dày hơn,
// mảnh và chậm. Tốc độ tính theo "chiều cao màn hình mỗi giây" nên không phụ thuộc độ phân giải.
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float slant = 0.12;
uniform float aspect = 1.7778;

float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

// columns: số cột; fall: màn hình mỗi giây; streak: độ dài vệt (tỉ lệ ô); width: độ mảnh; density: tỉ lệ cột có mưa.
float layer(vec2 uv, float columns, float fall, float streak, float width, float density, float seed) {
	vec2 p = vec2((uv.x + uv.y * slant) * columns * aspect, uv.y * 3.0 - TIME * fall * 3.0);
	float col = floor(p.x);
	float y = p.y + hash(col + seed) * 23.0;
	float cell = floor(y);
	float show = step(hash(col * 1.37 + cell * 3.1 + seed), density);
	float fy = fract(y);
	float fx = abs(fract(p.x) - 0.5);
	float body = 1.0 - smoothstep(width * 0.3, width, fx);
	// Đầu vệt sáng hơn, đuôi mờ dần.
	float tail = step(fy, streak) * (fy / streak);
	return body * tail * show;
}

void fragment() {
	float d = intensity;
	float far = layer(UV, 46.0, 0.32, 0.30, 0.10, d * 0.28, 1.0) * 0.30;
	float mid = layer(UV, 30.0, 0.50, 0.34, 0.11, d * 0.22, 7.0) * 0.40;
	float near = layer(UV, 17.0, 0.78, 0.38, 0.12, d * 0.14, 13.0) * 0.50;
	float rain = clamp(far + mid + near, 0.0, 1.0);
	// Chỉ lớp sương rất mỏng, để biển vẫn rõ.
	float haze = d * 0.05;
	COLOR = vec4(mix(vec3(0.10, 0.16, 0.22), vec3(0.82, 0.9, 0.97), rain), max(rain * 0.7, haze));
}
