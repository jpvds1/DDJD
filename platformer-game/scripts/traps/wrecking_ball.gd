extends Node3D


@onready var spike_ball: MeshInstance3D = $Visuals/Icosphere
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var max_angle := 30.0
@export var swings_per_second := 1.0
@export var spins_per_second := 1.0
@export var swing := 0.0:
	set(value):
		if value >= -1 && value <= 1:
			swing = value

var spin_speed := spins_per_second * 2 * PI


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player.speed_scale = swings_per_second


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# swing the wrecking ball around its pivot
	rotation_degrees.z = swing * max_angle
	
	# spin the spike ball
	spike_ball.rotate_y(spin_speed * delta)
