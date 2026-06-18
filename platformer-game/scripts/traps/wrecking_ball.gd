extends Node3D

@onready var wrecking_ball: Node3D = $Ball
@onready var visuals: Node3D = $Ball/Visuals

## The initial angle in degrees at which the wrecking ball is positioned.
@export var initial_angle := 0.0
## The amplitude in degrees of the swinging motion.
@export var max_angle := 30.0
## The duration in seconds of the swinging motion. A swing is considered going from the maximum angle to the minimum angle.
@export var swing_duration := 1.0

var spin_speed: float:
	get:
		return 0.7 * (TAU / swing_duration) # radians per second


func _create_tween(loop: bool) -> Tween:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_loops(0 if loop else 1)
	
	return tween


# Configures the swing looping animation.
func _swing() -> void:
	var tween := _create_tween(true)
	tween.tween_property(wrecking_ball, "rotation_degrees:z", -max_angle, swing_duration)
	tween.tween_property(wrecking_ball, "rotation_degrees:z", max_angle, swing_duration)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	wrecking_ball.rotation_degrees.z = clamp(initial_angle, -max_angle, max_angle) 
	
	# play the initial animation (needed if the initial angle differs from the maximum angle)
	var tween := _create_tween(false)
	var initial_swing_duration := swing_duration * ((max_angle - initial_angle) / (2 * max_angle))
	
	tween.tween_property(wrecking_ball, "rotation_degrees:z", max_angle, initial_swing_duration)
	
	# start the looping animation once the initial animation finishes
	tween.finished.connect(_swing)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# infinitely spin the spike ball
	visuals.rotate_y(spin_speed * delta)
