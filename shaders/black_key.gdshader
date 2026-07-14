shader_type canvas_item;

// Removes a near-black background from JPG icon art (skill_*.jpg) using normal alpha blending,
// so whatever sits behind the icon (e.g. a gauge fill) is properly occluded by the bright
// parts of the art instead of bleeding through like BLEND_MODE_ADD does.
uniform float threshold : hint_range(0.0, 1.0) = 0.14;
uniform float softness  : hint_range(0.0, 0.5) = 0.10;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	float brightness = max(tex_color.r, max(tex_color.g, tex_color.b));
	float key = smoothstep(threshold, threshold + softness, brightness);
	tex_color.a *= key;
	COLOR = tex_color;
}
