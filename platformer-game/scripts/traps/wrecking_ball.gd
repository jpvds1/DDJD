@tool
extends Node3D


@onready var wrecking_ball: Node3D = $Ball
@onready var visuals: Node3D = $Ball/Visuals
@onready var audio_stream_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

var _elapsed_time := 0.0 # seconds
var _spin_speed: float:
	get:
		return 0.7 * (TAU / swing_duration) # radians per second

## Whether the wrecking is swinging.
@export var active := true:
	set(value):
		active = value
		if is_node_ready():
			_start_swinging()
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


func _start_swinging() -> void:
	audio_stream_player.stop()
	_elapsed_time = (max_angle - rotation_degrees.z) / (2 * max_angle) * swing_duration

	# configure the audio player
	if active and not Engine.is_editor_hint():
		var audio_duration := audio_stream_player.stream.get_length()
		audio_stream_player.pitch_scale = audio_duration / swing_duration
		audio_stream_player.play(_elapsed_time * audio_duration)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	rotation_degrees.z = initial_angle
	_start_swinging()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if not active:
		return
	
	# infinitely swing the wrecking ball
	wrecking_ball.rotation_degrees.z = max_angle * cos(_elapsed_time * PI / swing_duration)
	_elapsed_time += delta
	
	# infinitely spin the spike ball
	visuals.rotate_y(_spin_speed * delta)
