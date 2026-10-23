shader_type canvas_item;
render_mode unshaded;

// Keep the feet pinned while the upper silhouette and loose fabric move.
// UVs refer to the source atlas, so clamp every sample to the active pose.
uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);
uniform float motion = 1.0;
uniform float phase = 0.0;
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 p = (UV - region.xy) / region.zw;
	float upper = pow(clamp(1.0 - p.y, 0.0, 1.0), 2.0);
	p.x += sin(TIME * 1.7 + phase + p.y * 5.0) * 0.007 * upper * motion;
	p.x += sin(TIME * 3.2 + p.y * 21.0 + phase) * 0.002 * upper * motion;
	p.y += sin(TIME * 1.9 + phase) * 0.003 * upper * motion;
	vec2 sample_uv = region.xy + clamp(p, vec2(0.001), vec2(0.999)) * region.zw;
	COLOR = tint * texture(TEXTURE, sample_uv);
}
