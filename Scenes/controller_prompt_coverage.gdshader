shader_type canvas_item;

// Preserve the original controller artwork, but recover the half-pixel strokes
// that disappear when a 120/240 px prompt is shown at only ~18 logical pixels.
// This is a tiny coverage expansion, not a replacement/simplification of the
// icon. At larger sizes the effect is visually negligible.
uniform float expand_texels = 1.90;
uniform float coverage_strength = 0.58;

float prompt_luma(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec4 center = texture(TEXTURE, UV);
	vec2 step_uv = TEXTURE_PIXEL_SIZE * expand_texels;
	vec4 brightest = center;
	float brightest_value = prompt_luma(center.rgb) * center.a;

	vec4 sample_color;
	float sample_value;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			if (x == 0 && y == 0) {
				continue;
			}
			sample_color = texture(TEXTURE, UV + vec2(float(x), float(y)) * step_uv);
			sample_value = prompt_luma(sample_color.rgb) * sample_color.a;
			if (sample_value > brightest_value) {
				brightest = sample_color;
				brightest_value = sample_value;
			}
		}
	}

	float center_value = prompt_luma(center.rgb) * center.a;
	float missing_coverage = max(0.0, brightest_value - center_value);
	float blend = clamp(missing_coverage * coverage_strength * 1.65, 0.0, 0.48);
	vec4 result = mix(center, brightest, blend);
	result.a = max(center.a, brightest.a * blend);
	COLOR = result;
}
