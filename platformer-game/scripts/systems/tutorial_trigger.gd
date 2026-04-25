extends Area3D

@export var detection_radius: float = 5.0:
	set(value):
		detection_radius = value
		update_collision_radius()

@export_multiline var tutorial_text: String = "temp"

@onready var label = $Label3D
@onready var collision_shape = $CollisionShape3D

func _ready():
	label.text = tutorial_text
	label.visible = false
	
	update_collision_radius()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func update_collision_radius():
	if collision_shape and collision_shape.shape is SphereShape3D:
		collision_shape.shape.radius = detection_radius

func _on_body_entered(body):
	if body.is_in_group("player"):
		label.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		label.visible = false
