shader_type canvas_item;

// Removes a near-white background from JPG/PNG art that wasn't exported with alpha,
// so character art can sit directly on the battle background without a white box.
uniform float threshold : hint_range(0.0, 1.0) = 0.88;
uniform float softness  : hint_range(0.0, 0.5) = 0.12;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	float whiteness = min(tex_color.r, min(tex_color.g, tex_color.b));
	float key = smoothstep(threshold - softness, threshold, whiteness);
	tex_color.a *= (1.0 - key);
	COLOR = tex_color;
}
