// Flat ground decal used for ability telegraphs, range rings, aim indicators and unit rings.
// Drawn on a horizontal PlaneMesh slightly above the ground.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.4, 0.25, 0.85);
// 0 = ring, 1 = disc, 2 = rectangle, 3 = skillshot (rectangle with moving chevrons)
uniform int shape = 0;
// Telegraph fill: circles grow from the center, rectangles grow along their length.
uniform float progress : hint_range(0.0, 1.0) = 0.0;
// Rim thickness in normalized units (fraction of the radius / half-width).
uniform float edge_width = 0.06;
// Rim thickness along the length of rectangles (fraction of the length).
uniform float end_width = 0.01;
uniform float fill_alpha : hint_range(0.0, 1.0) = 0.15;
uniform float progress_alpha : hint_range(0.0, 1.0) = 0.35;
uniform float pulse_speed = 0.0;

float aa_edge(float edge, float x) {
	float w = max(fwidth(x), 0.0005) * 1.25;
	return smoothstep(edge - w, edge + w, x);
}

void fragment() {
	float alpha = 0.0;
	float pulse = 1.0 + (pulse_speed > 0.0 ? 0.15 * sin(TIME * pulse_speed) : 0.0);
	if (shape <= 1) {
		vec2 p = UV * 2.0 - 1.0;
		float d = length(p);
		float inside = 1.0 - aa_edge(0.995, d);
		float rim = inside * aa_edge(1.0 - edge_width, d);
		float fill = shape == 1 ? fill_alpha : 0.0;
		float prog = progress > 0.001 ? (1.0 - aa_edge(progress, d)) * progress_alpha : 0.0;
		float ripple = shape == 1 && progress > 0.001 ? aa_edge(progress - 0.04, d) * (1.0 - aa_edge(progress, d)) * 0.5 : 0.0;
		alpha = max(rim * pulse, (fill + prog + ripple) * inside);
	} else {
		// x: -1..1 across the width, y: 0 at the origin end .. 1 at the far end.
		vec2 p = vec2(UV.x * 2.0 - 1.0, 1.0 - UV.y);
		float ax = abs(p.x);
		float inside = (1.0 - aa_edge(0.995, ax)) * (1.0 - aa_edge(0.998, p.y)) * aa_edge(0.002, p.y);
		float side_rim = aa_edge(1.0 - edge_width, ax);
		float end_rim = aa_edge(1.0 - end_width, p.y);
		float rim = max(side_rim, end_rim) * inside;
		float prog = progress > 0.001 ? (1.0 - aa_edge(progress, p.y)) * progress_alpha : 0.0;
		float chevrons = 0.0;
		if (shape == 3) {
			float c = fract(p.y * 7.0 - TIME * 1.6 - ax * 0.35);
			chevrons = (aa_edge(0.0, c) * (1.0 - aa_edge(0.12, c))) * 0.3;
		}
		alpha = max(rim * pulse, (fill_alpha + prog + chevrons) * inside);
	}
	ALBEDO = color.rgb;
	ALPHA = clamp(alpha, 0.0, 1.0) * color.a;
}
