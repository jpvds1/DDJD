extends Node3D

@onready var wrecking_ball: Node3D = $Ball
@onready var visuals: Node3D = $Ball/Visuals

@export var max_angle := 30.0
@export var swings_per_second := 1.0

var spin_speed: float:
	get:
		return 0.7 * swings_per_second * 2 * PI # radians per second


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# set up the tweener
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_loops() # loop infinitely
	
	# configure the animation keyframes
	var swing_duration := 1.0 / swings_per_second # seconds
	tween.tween_property(wrecking_ball, "rotation_degrees:z", max_angle, swing_duration)
	tween.tween_property(wrecking_ball, "rotation_degrees:z", -max_angle, swing_duration)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# infinitely spin the spike ball
	visuals.rotate_y(spin_speed * delta)
