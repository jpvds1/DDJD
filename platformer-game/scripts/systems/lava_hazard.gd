extends Area3D

@export var velocidad: float = 2.0
@export var amplitud: float = 0.2

var posicion_inicial_y: float = 0.0
@onready var bloque_visual: Node3D = get_parent() as Node3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if bloque_visual:
		posicion_inicial_y = bloque_visual.position.y

func _process(_delta: float) -> void:
	if not bloque_visual:
		return

	var tiempo: float = Time.get_ticks_msec() * 0.001
	bloque_visual.position.y = posicion_inicial_y + sin(tiempo * velocidad) * amplitud

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("request_unalive"):
		body.request_unalive()
