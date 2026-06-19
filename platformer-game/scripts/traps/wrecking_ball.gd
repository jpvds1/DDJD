@tool
extends Node3D

@onready var wrecking_ball: Node3D = $Ball
@onready var visuals: Node3D = $Ball/Visuals

var _elapsed_time := 0.0 # seconds
var _spin_speed: float:
	get:
		return 0.7 * (TAU / swing_duration) # radians per second


## The initial angle in degrees at which the wrecking ball is positioned.
@export var initial_angle := 0.0
## The amplitude in degrees of the swinging motion.
@export_range(0, 90, 0.1) var max_angle := 30.0
## The duration in seconds of the swinging motion. A swing is considered going from the maximum angle to the minimum angle.
@export var swing_duration := 1.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	max_angle = abs(max_angle)
	initial_angle = clamp(initial_angle, -max_angle, max_angle)
	_elapsed_time = swing_duration * (max_angle - initial_angle) / (2 * max_angle)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# infinitely swing the wrecking ball
	wrecking_ball.rotation_degrees.z = max_angle * sin(2 * _elapsed_time / swing_duration)
	_elapsed_time += delta
	
	# infinitely spin the spike ball
	visuals.rotate_y(_spin_speed * delta)
