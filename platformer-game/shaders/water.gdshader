shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform float wave_speed : hint_range(0.1, 5.0) = 1.2;
uniform float wave_scale : hint_range(0.1, 10.0) = 3.0;
uniform vec4 shallow_color : source_color = vec4(0.1, 0.6, 1.0, 0.55);
uniform vec4 deep_color : source_color = vec4(0.0, 0.25, 0.7, 0.85);
uniform float foam_threshold : hint_range(0.0, 1.0) = 0.7;
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 0.9);

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
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.1;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	float t = TIME * wave_speed;
	vec2 uv = UV * wave_scale;

	float n1 = fbm(uv + vec2(t * 0.5, t * 0.3));
	float n2 = fbm(uv * 1.3 - vec2(t * 0.3, t * 0.6));
	float n = (n1 + n2) * 0.5;

	vec4 col = mix(deep_color, shallow_color, n);

	float foam = smoothstep(foam_threshold, 1.0, n);
	col = mix(col, foam_color, foam * 0.5);

	ALBEDO = col.rgb;
	ALPHA = col.a;
	ROUGHNESS = 0.05;
	METALLIC = 0.1;
	SPECULAR = 0.9;

	float eps = 0.02;
	float nx = fbm(uv + vec2(eps, 0.0) + vec2(t * 0.5, t * 0.3)) - n1;
	float nz = fbm(uv + vec2(0.0, eps) + vec2(t * 0.5, t * 0.3)) - n1;
	NORMAL_MAP = normalize(vec3(nx, nz, 0.3) * 0.5 + 0.5);
	NORMAL_MAP_DEPTH = 2.0;
}
