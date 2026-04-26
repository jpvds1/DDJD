extends CSGBox3D

@export var velocidad_olas: float = 1.0
@export var altura_olas: float = 0.25
@export var velocidad_corriente: float = 0.1

var _posicion_inicial_y: float = 0.0
var _material_agua: StandardMaterial3D

func _ready() -> void:
	# Guardamos la altura inicial para que la oscilación parta desde ahí.
	_posicion_inicial_y = global_position.y

	# Duplicamos el material para que el movimiento UV afecte solo a este agua.
	if material is StandardMaterial3D:
		_material_agua = (material as StandardMaterial3D).duplicate() as StandardMaterial3D
		material = _material_agua


func _physics_process(_delta: float) -> void:
	# Oscilación vertical suave para simular el movimiento del agua.
	var desplazamiento_vertical: float = sin(Time.get_ticks_msec() / 1000.0 * velocidad_olas) * altura_olas
	var nueva_posicion: Vector3 = global_position
	nueva_posicion.y = _posicion_inicial_y + desplazamiento_vertical
	global_position = nueva_posicion


func _process(delta: float) -> void:
	if _material_agua == null:
		return

	# Desplazamos el UV para crear el efecto visual de corriente.
	var uv_offset: Vector3 = _material_agua.uv1_offset
	uv_offset.x += velocidad_corriente * delta
	_material_agua.uv1_offset = uv_offset
