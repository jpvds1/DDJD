@tool
extends Node3D

@onready var wrecking_ball: Node3D = $Ball
@onready var visuals: Node3D = $Ball/Visuals

var _elapsed_time := 0.0 # seconds
var _spin_speed: float:
	get:
		return 0.7 * (TAU / swing_duration) # radians per second

## Whether the wrecking is swinging.
@export var active := true
## The amplitude in degrees of the swinging motion.
@export_range(0, 90, 0.1) var max_angle := 30.0:
	set(value):
		max_angle = abs(value)
## The initial angle in degrees at which the wrecking ball is positioned.
@export var initial_angle := 0.0:
	set(value):
		initial_angle = clamp(value, -max_angle, max_angle)
## The duration in seconds of the swinging motion. A swing is considered going from the maximum angle to the minimum angle.
@export var swing_duration := 1.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_elapsed_time = (max_angle - initial_angle) / (2 * max_angle) * swing_duration


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not active:
		return
	
	# infinitely swing the wrecking ball
	wrecking_ball.rotation_degrees.z = max_angle * cos(_elapsed_time * PI / swing_duration)
	_elapsed_time += delta
	
	# infinitely spin the spike ball
	visuals.rotate_y(_spin_speed * delta)
