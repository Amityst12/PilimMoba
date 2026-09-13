// Stylized arena ground: grass, dirt lane, stone base plazas, river and dark map border.
// Regions are computed analytically from world position, so the map layout can change
// without repainting textures.
shader_type spatial;
render_mode cull_back;

uniform vec3 grass_light : source_color = vec3(0.33, 0.52, 0.24);
uniform vec3 grass_dark : source_color = vec3(0.19, 0.36, 0.17);
uniform vec3 dirt : source_color = vec3(0.52, 0.42, 0.3);
uniform vec3 dirt_dark : source_color = vec3(0.38, 0.3, 0.21);
uniform vec3 stone : source_color = vec3(0.5, 0.5, 0.52);
uniform vec3 water_shallow : source_color = vec3(0.22, 0.55, 0.6);
uniform vec3 water_deep : source_color = vec3(0.08, 0.26, 0.38);
uniform vec3 border : source_color = vec3(0.1, 0.13, 0.1);
uniform vec3 blue_tint : source_color = vec3(0.3, 0.55, 1.0);
uniform vec3 red_tint : source_color = vec3(1.0, 0.35, 0.35);

uniform vec2 map_half = vec2(66.0, 34.0);
uniform float lane_half_width = 7.5;
uniform float lane_end_x = 52.0;
uniform float river_half_width = 4.2;
uniform vec2 blue_base = vec2(-57.0, 0.0);
uniform vec2 red_base = vec2(57.0, 0.0);
uniform float base_radius = 12.5;
uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float n = texture(noise_tex, p * 0.018).r;
	float n2 = texture(noise_tex, p * 0.11).r;
	float n3 = texture(noise_tex, p * 0.6).r;

	vec3 col = mix(grass_dark, grass_light, smoothstep(0.25, 0.75, n));
	col *= 0.86 + 0.22 * n2;
	col *= 0.94 + 0.12 * n3;

	// Dirt lane with ragged edges.
	float lane_edge = lane_half_width + (n2 - 0.5) * 2.2;
	float lane = (1.0 - smoothstep(lane_edge - 1.2, lane_edge + 0.3, abs(p.y)))
			* (1.0 - smoothstep(lane_end_x - 2.0, lane_end_x + 3.0, abs(p.x)));
	vec3 lane_col = mix(dirt_dark, dirt, smoothstep(0.2, 0.8, n3)) * (0.9 + 0.15 * n2);
	// Wheel ruts along the lane.
	float ruts = smoothstep(0.35, 0.0, abs(abs(p.y) - 2.2 - (n - 0.5)));
	lane_col *= 1.0 - ruts * 0.12;
	col = mix(col, lane_col, lane);

	// Stone plazas in both bases, tinted by team.
	float d_blue = distance(p, blue_base);
	float d_red = distance(p, red_base);
	float base_edge = base_radius + (n2 - 0.5) * 1.5;
	float blue_plaza = 1.0 - smoothstep(base_edge - 0.6, base_edge + 0.4, d_blue);
	float red_plaza = 1.0 - smoothstep(base_edge - 0.6, base_edge + 0.4, d_red);
	vec2 tile = abs(fract(p * 0.45) - 0.5);
	float grout = smoothstep(0.43, 0.5, max(tile.x, tile.y));
	vec3 stone_col = stone * (0.82 + 0.25 * n3) * (1.0 - grout * 0.4);
	float rings = smoothstep(0.08, 0.0, abs(fract(min(d_blue, d_red) * 0.25) - 0.5) - 0.42);
	stone_col *= 1.0 - rings * 0.15;
	col = mix(col, stone_col * mix(vec3(1.0), blue_tint, 0.12), blue_plaza);
	col = mix(col, stone_col * mix(vec3(1.0), red_tint, 0.12), red_plaza);

	// River crossing the middle of the map.
	float river_x = p.x + sin(p.y * 0.12) * 1.6;
	float river_edge = river_half_width + (n2 - 0.5) * 0.8;
	float river = 1.0 - smoothstep(river_edge - 0.4, river_edge + 0.3, abs(river_x));
	float depth = smoothstep(river_edge, 0.0, abs(river_x));
	vec3 water = mix(water_shallow, water_deep, depth * 0.8);
	float ripple = sin(TIME * 1.3 + p.y * 1.1 + n2 * 8.0) * sin(TIME * 0.9 - p.x * 1.7 + n3 * 5.0);
	water += vec3(0.05, 0.08, 0.09) * ripple;
	float shore = smoothstep(0.35, 0.0, abs(abs(river_x) - river_edge));
	water = mix(water, vec3(0.75, 0.85, 0.8), shore * 0.25);
	col = mix(col, water, river);

	// Dark forest floor outside the playable area.
	float outside = max(smoothstep(map_half.x - 1.0, map_half.x + 3.0, abs(p.x)),
			smoothstep(map_half.y - 1.0, map_half.y + 3.0, abs(p.y)));
	col = mix(col, border * (0.8 + 0.4 * n2), outside);

	ALBEDO = col;
	ROUGHNESS = mix(0.92, 0.12, river);
	SPECULAR = mix(0.25, 0.7, river);
}
