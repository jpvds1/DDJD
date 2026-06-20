extends CSGBox3D

@export var wave_speed: float = 1.0
@export var wave_height: float = 0.25
@export var wave_frequency: float = 1.0
@export var current_speed: float = 0.1

var _initial_y_position: float = 0.0
var _water_material: ShaderMaterial
var _uv_scroll_offset: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	# Store initial height so waves start from the correct position.
	_initial_y_position = global_position.y

	# Create water material by code to animate vertices and UVs.
	_water_material = ShaderMaterial.new()
	_water_material.shader = Shader.new()
	_water_material.shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 water_color : source_color = vec4(0.0, 0.45, 0.85, 0.5);
uniform float wave_speed = 1.0;
uniform float wave_height = 0.25;
uniform float wave_frequency = 1.0;
uniform float uv_scroll_offset = 0.0;

void vertex() {
		// Only deform the upper face so the bottom stays fixed.
	if (VERTEX.y > 0.0) {
		float wave = sin(TIME * wave_speed + (VERTEX.x + VERTEX.z) * wave_frequency) * wave_height;
		VERTEX.y += wave;
	}
}

void fragment() {
	vec2 uv = UV;
	uv.x += uv_scroll_offset;

	float shimmer = sin((uv.x * 12.0 + uv_scroll_offset) * 6.0) * 0.03;

	ALBEDO = water_color.rgb + vec3(shimmer);
	EMISSION = vec3(max(shimmer, 0.0)) * 0.15;
	ALPHA = water_color.a;
}
"""
	material = _water_material
	# Adjust intensity from Inspector: increase `wave_height` for more amplitude and `wave_frequency` for more crests.
	_water_material.set_shader_parameter("water_color", Color(0.0, 0.45, 0.85, 0.5))
	_water_material.set_shader_parameter("wave_speed", wave_speed)
	_water_material.set_shader_parameter("wave_height", wave_height)
	_water_material.set_shader_parameter("wave_frequency", wave_frequency)

func _physics_process(_delta: float) -> void:
	# Waves are animated in the shader; here we keep the material in sync with the Inspector.
	if _water_material == null:
		return

	_water_material.set_shader_parameter("wave_speed", wave_speed)
	_water_material.set_shader_parameter("wave_height", wave_height)
	_water_material.set_shader_parameter("wave_frequency", wave_frequency)

func _process(delta: float) -> void:
	if _water_material == null:
		return

	# Scroll surface shimmer with UV offset.
	_uv_scroll_offset += current_speed * delta
	_water_material.set_shader_parameter("uv_scroll_offset", _uv_scroll_offset)
