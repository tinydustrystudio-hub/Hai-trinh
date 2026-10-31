shader_type canvas_item;
// Màn mưa phủ toàn màn hình: ba lớp vệt mưa rơi xiên theo gió; lớp gần dày và nhanh, lớp xa mảnh và chậm.
// intensity (0–1) quyết định mật độ; slant là độ xiên theo gió.
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float slant = 0.15;
uniform float aspect = 1.7778;

float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

float layer(vec2 uv, float columns, float rows, float speed, float length, float seed, float width) {
	vec2 p = vec2((uv.x + uv.y * slant) * columns * aspect, uv.y * rows + TIME * speed);
	float col = floor(p.x);
	float r = hash(col + seed);
	float y = p.y + r * 17.0;
	float cell = floor(y);
	float show = step(hash(col * 1.37 + cell * 3.1 + seed), intensity * 0.55);
	float fy = fract(y);
	float fx = abs(fract(p.x) - 0.5);
	float line = (1.0 - smoothstep(width * 0.4, width, fx)) * step(fy, length) * (fy / length);
	return line * show;
}

void fragment() {
	float far = layer(UV, 38.0, 6.0, 7.0, 0.5, 1.0, 0.07) * 0.35;
	float mid = layer(UV, 24.0, 4.0, 11.0, 0.55, 7.0, 0.09) * 0.5;
	float near = layer(UV, 13.0, 2.5, 17.0, 0.6, 13.0, 0.12) * 0.7;
	float rain = clamp(far + mid + near, 0.0, 1.0);
	// Phủ một lớp xám lam mỏng cho cảm giác ẩm ướt.
	float haze = intensity * 0.12;
	COLOR = vec4(mix(vec3(0.05, 0.1, 0.16), vec3(0.78, 0.86, 0.95), rain), max(rain * 0.55, haze));
}
