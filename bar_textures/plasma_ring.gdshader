shader_type canvas_item;

uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform float show : hint_range(0.0, 1.0)   = 1.0;

void fragment() {
    vec2 uv  = UV - vec2(0.5);
    float dist  = length(uv);
    float angle = atan(uv.y, uv.x);

    // clip วงกลม — ตัดขอบสี่เหลี่ยมออก
    float circle_mask = 1.0 - smoothstep(0.47, 0.50, dist);
    if (circle_mask < 0.01) discard;

    float h0[5] = float[](295.0, 255.0, 215.0, 325.0, 188.0);
    float h1[5] = float[](345.0, 300.0, 265.0, 360.0, 238.0);
    float radii[5]  = float[](0.44, 0.36, 0.27, 0.48, 0.19);
    float widths[5] = float[](0.065,0.052,0.040,0.020,0.030);
    float speeds[5] = float[](0.80,-1.10, 1.50,-0.55,-2.00);
    float ba[5]     = float[](0.92, 0.86, 0.80, 0.50, 0.65);

    vec4 col = vec4(0.0);

    for (int i = 0; i < 5; i++) {
        float rot = time * speeds[i];
        float a   = angle + rot;
        float t   = fract(a / (2.0 * 3.14159) + 1.0);

        float hue = mix(h0[i], h1[i], t) / 360.0;

        float w1 = 0.5 + 0.5 * cos(t * 3.14159 * 4.0 - time * 0.3 * speeds[i]);
        float w2 = 0.5 + 0.5 * cos(t * 3.14159 * 6.0 + time * 0.5 * speeds[i]);
        float w3 = 0.5 + 0.5 * cos(t * 3.14159 * 2.0 - time * 0.2 * speeds[i]);
        float bright = w1 * 0.45 + w2 * 0.3 + w3 * 0.25;

        float topLight = 0.55 + 0.45 * (-sin(a));
        float ring     = exp(-pow((dist - radii[i]) / widths[i], 2.0));

        // HSL → RGB
        float h6    = hue * 6.0;
        float x_val = 1.0 - abs(mod(h6, 2.0) - 1.0);
        vec3 rgb;
        if      (h6 < 1.0) rgb = vec3(1.0,   x_val, 0.0);
        else if (h6 < 2.0) rgb = vec3(x_val, 1.0,   0.0);
        else if (h6 < 3.0) rgb = vec3(0.0,   1.0,   x_val);
        else if (h6 < 4.0) rgb = vec3(0.0,   x_val, 1.0);
        else if (h6 < 5.0) rgb = vec3(x_val, 0.0,   1.0);
        else               rgb = vec3(1.0,   0.0,   x_val);

        float lum = 0.55 + topLight * 0.22;
        rgb = mix(vec3(lum), rgb, 0.85) * lum * 1.3;

        float alpha = show * ba[i] * bright * (0.68 + 0.32 * topLight) * ring;

        // glow layer
        float glow = exp(-pow((dist - radii[i]) / (widths[i] * 2.8), 2.0));
        col.rgb += rgb * glow * alpha * 0.5;
        // core line
        col.rgb += rgb * ring * alpha * 0.95;
        col.a   += ring * alpha;
    }

    // center core glow
    float core_o = exp(-pow(dist / 0.22, 2.0)) * 0.55;
    float core_i = exp(-pow(dist / 0.09, 2.0));
    float core   = min(1.0, core_o + core_i);
    vec3 core_col = mix(vec3(0.6, 0.3, 1.0), vec3(1.0), core_i);
    col.rgb += core_col * core * show;
    col.a   += core * show * 0.95;

    // ambient
    float amb = exp(-pow(dist / 0.38, 2.0)) * 0.16 * show;
    col.rgb += vec3(0.4, 0.1, 0.8) * amb;

    // apply circle mask
    col     = clamp(col, 0.0, 1.0);
    col.a  *= circle_mask;
    COLOR   = col;
}
