shader_type canvas_item;

uniform float progress  : hint_range(0.0, 1.0) = 0.5;
uniform float bar_alpha : hint_range(0.0, 1.0) = 1.0;
uniform float pulse_val : hint_range(0.0, 1.0) = 1.0;
uniform float time_val  : hint_range(0.0, 1000.0) = 0.0;

// Rounded-rect SDF centered at origin
float pill_sdf(vec2 p, float hw, float hh, float r) {
	vec2 q = abs(p) - vec2(hw - r, hh - r);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	// Bar rect is 992 x 44 px — aspect for pill SDF
	float aspect = 992.0 / 44.0;
	vec2  p = vec2((UV.x - 0.5) * aspect, UV.y - 0.5);
	float r = 0.5; // radius = half-height → perfect pill

	// ── Track (background) ────────────────────────────────────────────────
	float track_d = pill_sdf(p, aspect * 0.5, 0.5, r);
	float track_m = 1.0 - smoothstep(-0.02, 0.02, track_d);
	if (track_m < 0.005) { discard; }

	vec3 track_col = vec3(0.01, 0.04, 0.14);

	// Inner rim glow on track edge
	float rim = smoothstep(2.5, 0.0, abs(track_d) * 44.0) * 0.35;
	track_col += vec3(0.2, 0.55, 1.0) * rim;

	// ── Fill pill ─────────────────────────────────────────────────────────
	float fill_w  = aspect * progress;
	float fill_cx = -aspect * 0.5 + fill_w * 0.5;
	float fill_d  = pill_sdf(p - vec2(fill_cx, 0.0), fill_w * 0.5, 0.5, r);
	float fill_m  = (1.0 - smoothstep(-0.02, 0.02, fill_d)) * track_m;

	// Smooth gradient: deep navy → bright cyan
	float grad_t   = clamp(UV.x / max(progress, 0.001), 0.0, 1.0);
	vec3  col_l    = vec3(0.04, 0.32, 0.92);
	vec3  col_r    = vec3(0.18, 0.88, 1.00);
	vec3  fill_col = mix(col_l, col_r, pow(grad_t, 0.65));

	// Top highlight — brighter near top edge
	float hi = smoothstep(0.5, 0.02, UV.y);
	fill_col += vec3(0.25, 0.30, 0.38) * hi;

	// Very thin bright line at top edge
	float top_line = smoothstep(0.06, 0.0, UV.y) * 0.55;
	fill_col       += vec3(0.8, 1.0, 1.0) * top_line;

	// Moving shimmer streak
	float sh_t   = fract(UV.x * 0.7 - time_val * 0.12);
	float shimmer = exp(-pow((sh_t - 0.5) * 6.0, 2.0)) * 0.30 * pulse_val;
	fill_col     += vec3(0.3, 0.65, 1.0) * shimmer;

	// Inner border glow on fill edge
	float fill_rim = smoothstep(2.0, 0.0, abs(fill_d) * 44.0) * fill_m * 0.45;
	fill_col += vec3(0.5, 0.92, 1.0) * fill_rim;

	// ── Composite ─────────────────────────────────────────────────────────
	vec3  final_col = mix(track_col, fill_col, fill_m);
	float final_a   = track_m * bar_alpha;

	COLOR = vec4(final_col, final_a);
}
