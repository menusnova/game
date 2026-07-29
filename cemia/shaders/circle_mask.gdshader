shader_type canvas_item;

// Clips a texture into a circle so square avatar art fits the round avatar ring.
// Soft 1px edge to avoid jaggies.
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float d = distance(UV, vec2(0.5, 0.5));
	float edge = fwidth(d) * 1.5;
	float mask = 1.0 - smoothstep(0.5 - edge, 0.5, d);
	tex.a *= mask;
	COLOR = tex;
}
