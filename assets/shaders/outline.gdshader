shader_type canvas_item;

// 외곽선 설정
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // 검정색
uniform float outline_width : hint_range(0.0, 10.0) = 2.0; // 외곽선 두께

void fragment() {
	// 원본 텍스처 색상
	vec4 original_color = texture(TEXTURE, UV);

	// 외곽선 검사 (8방향)
	float outline = 0.0;
	vec2 pixel_size = TEXTURE_PIXEL_SIZE * outline_width;

	// 8방향 샘플링
	outline += texture(TEXTURE, UV + vec2(-pixel_size.x, 0.0)).a;
	outline += texture(TEXTURE, UV + vec2(pixel_size.x, 0.0)).a;
	outline += texture(TEXTURE, UV + vec2(0.0, -pixel_size.y)).a;
	outline += texture(TEXTURE, UV + vec2(0.0, pixel_size.y)).a;
	outline += texture(TEXTURE, UV + vec2(-pixel_size.x, -pixel_size.y)).a;
	outline += texture(TEXTURE, UV + vec2(pixel_size.x, -pixel_size.y)).a;
	outline += texture(TEXTURE, UV + vec2(-pixel_size.x, pixel_size.y)).a;
	outline += texture(TEXTURE, UV + vec2(pixel_size.x, pixel_size.y)).a;

	// 외곽선 적용 (현재 픽셀이 투명하고 주변에 불투명 픽셀이 있으면)
	if (original_color.a < 0.1 && outline > 0.0) {
		COLOR = outline_color;
	} else {
		COLOR = original_color;
	}
}
