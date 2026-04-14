extends Node3D

@export var velocidad: float = 2.0
@export var amplitud: float = 30.0

var _rotacion_base_z: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_rotacion_base_z = rotation.z


# Called at a fixed interval. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	rotation.z = _rotacion_base_z + sin(Time.get_ticks_msec() / 1000.0 * velocidad) * deg_to_rad(amplitud)


func _on_ball_body_entered(body: Node3D) -> void:
	print("¡Jugador golpeado!")
	if body != null and body.has_method("request_unalive"):
		body.request_unalive()


func _on_area_3d_body_entered(body: Node3D) -> void:
	_on_ball_body_entered(body)
