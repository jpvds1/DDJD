extends Node3D

@export var rotation_speed: float = 24.0
@export var pulse_magnitude: float = 0.04
@export var pulse_speed: float = 1.8
@export var float_speed: float = 1.15
@export var float_amplitude: float = 0.08

var _base_scale: Vector3 = Vector3.ONE
var _phase_offset: float = 0.0
var _last_time: float = 0.0
var _initial_local_y: float = 0.0
var _float_phase_offset: float = 0.0


func _ready() -> void:
	randomize()
	_base_scale = scale
	_phase_offset = randf() * TAU
	_initial_local_y = position.y
	_float_phase_offset = randf() * TAU
	_last_time = Time.get_ticks_msec() * 0.001


func _process(_delta: float) -> void:
	var t: float = Time.get_ticks_msec() * 0.001
	var dt: float = t - _last_time
	_last_time = t
	position.y = _initial_local_y + sin(t * float_speed + _float_phase_offset) * float_amplitude

	rotation.y += deg_to_rad(rotation_speed) * dt

	var pulse: float = 1.0 + sin(t * pulse_speed + _phase_offset) * pulse_magnitude
	scale = _base_scale * pulse
