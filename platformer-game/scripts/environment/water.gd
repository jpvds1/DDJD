extends CSGBox3D

@export var wave_speed: float = 1.2
@export var current_speed: float = 0.1

var _uv_scroll_offset: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(delta: float) -> void:
	var mat := material as ShaderMaterial
	if mat == null:
		return
	_uv_scroll_offset += current_speed * delta
	mat.set_shader_parameter("wave_speed", wave_speed)
