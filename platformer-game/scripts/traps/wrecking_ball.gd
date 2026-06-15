extends Node3D

@export var max_angle: float = 30.0
@export var spins_per_second: float = 2
@export var swing: float = 0:
	set(value):
		if value >= -1 && value <= 1:
			swing = value

@onready var spike_ball: MeshInstance3D = $Visuals/Icosphere

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# swing the wrecking ball around its pivot
	rotation_degrees.z = swing * max_angle
	
	# spin the spike ball
	spike_ball.rotate_y(spins_per_second * delta)
