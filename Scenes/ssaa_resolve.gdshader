shader_type canvas_item;

// Ratio between the off-screen render target and the final physical window.
// At 1080p Theodore Ball renders at 2x in each axis (4K internally), then this
// shader performs an actual box resolve instead of a simple bilinear resize.
uniform vec2 resolve_scale = vec2(1.0);

void fragment() {
	if (resolve_scale.x <= 1.01 && resolve_scale.y <= 1.01) {
		COLOR = texture(TEXTURE, UV);
	} else {
		vec2 texel = TEXTURE_PIXEL_SIZE;
		// Four sample positions centered in the quarters of the destination pixel's
		// source footprint. For a 2x resolve these are +/- 0.5 source texels, which
		// is the proper 2x2 supersample resolve instead of just shrinking the image.
		vec2 offset = texel * resolve_scale * 0.25;
		vec4 c = vec4(0.0);
		c += texture(TEXTURE, UV + vec2(-offset.x, -offset.y));
		c += texture(TEXTURE, UV + vec2( offset.x, -offset.y));
		c += texture(TEXTURE, UV + vec2(-offset.x,  offset.y));
		c += texture(TEXTURE, UV + vec2( offset.x,  offset.y));
		COLOR = c * 0.25;
	}
}
