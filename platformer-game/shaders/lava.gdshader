shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, unshaded;

uniform float flow_speed : hint_range(0.05, 2.0) = 0.3;
uniform float flow_scale : hint_range(0.5, 8.0) = 2.5;
uniform vec4 hot_color : source_color = vec4(1.0, 0.98, 0.5, 1.0);
uniform vec4 mid_color : source_color = vec4(1.0, 0.18, 0.0, 1.0);
uniform vec4 cool_color : source_color = vec4(0.35, 0.0, 0.0, 1.0);
uniform float crust_threshold : hint_range(0.0, 1.0) = 0.55;
uniform float emission_strength : hint_range(0.0, 12.0) = 6.0;
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1, 0)), f.x),
		mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x),
		f.y
	);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	float t = TIME * flow_speed;
	vec2 uv = UV * flow_scale;

	vec2 dir1 = vec2(t * 0.6, t * 0.4);
	vec2 dir2 = vec2(-t * 0.3, t * 0.7);
	vec2 dir3 = vec2(t * 0.15, -t * 0.5);

	float n1 = fbm(uv + dir1);
	float n2 = fbm(uv * 1.5 + dir2);
	float n3 = fbm(uv * 0.7 + dir3);
	float n = (n1 * 0.5 + n2 * 0.35 + n3 * 0.15);

	vec4 col;
	if (n < crust_threshold * 0.5) {
		col = mix(hot_color, mid_color, n / (crust_threshold * 0.5));
	} else {
		col = mix(mid_color, cool_color, (n - crust_threshold * 0.5) / (1.0 - crust_threshold * 0.5));
	}

	float heat = 1.0 - smoothstep(0.0, crust_threshold, n);
	ALBEDO = col.rgb;
	ALPHA = 1.0;
	EMISSION = mix(mid_color.rgb * 0.4, hot_color.rgb, heat) * emission_strength * heat;
	ROUGHNESS = mix(0.95, 0.2, heat);

	float eps = 0.025;
	float dnx = fbm(uv + vec2(eps, 0.0) + dir1) - n1;
	float dnz = fbm(uv + vec2(0.0, eps) + dir1) - n1;
	NORMAL_MAP = normalize(vec3(dnx, dnz, 0.2) * 0.5 + 0.5);
	NORMAL_MAP_DEPTH = 3.0;
}
