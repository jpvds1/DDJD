extends CSGBox3D

@export var velocidad_olas: float = 1.0
@export var altura_olas: float = 0.25
@export var frecuencia_ondas: float = 1.0
@export var velocidad_corriente: float = 0.1

var _initial_y_position: float = 0.0
var _water_material: ShaderMaterial
var _uv_scroll_offset: float = 0.0

func _ready() -> void:
	# Guarda la altura inicial para que las olas partan desde la posición correcta.
	_initial_y_position = global_position.y

	# Creamos el material del agua por código para animar vértices y UVs.
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
	// Solo deformamos la cara superior para que el fondo quede fijo en la piscina.
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
	# Ajusta la intensidad desde el Inspector: sube `altura_olas` para más altura y `frecuencia_ondas` para más crestas.
	_water_material.set_shader_parameter("water_color", Color(0.0, 0.45, 0.85, 0.5))
	_water_material.set_shader_parameter("wave_speed", velocidad_olas)
	_water_material.set_shader_parameter("wave_height", altura_olas)
	_water_material.set_shader_parameter("wave_frequency", frecuencia_ondas)

func _physics_process(_delta: float) -> void:
	# Las olas se animan en el shader; aquí solo mantenemos el material sincronizado con el Inspector.
	if _water_material == null:
		return

	_water_material.set_shader_parameter("wave_speed", velocidad_olas)
	_water_material.set_shader_parameter("wave_height", altura_olas)
	_water_material.set_shader_parameter("wave_frequency", frecuencia_ondas)

func _process(delta: float) -> void:
	if _water_material == null:
		return

	# Desplazamos el brillo de la superficie con un offset UV equivalente a uv1_offset.
	_uv_scroll_offset += velocidad_corriente * delta
	_water_material.set_shader_parameter("uv_scroll_offset", _uv_scroll_offset)
