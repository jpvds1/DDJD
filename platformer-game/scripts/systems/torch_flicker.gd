extends Node3D

@export var light_node: OmniLight3D
@export var particle_node: GPUParticles3D

@export var energy_min: float = 1.4
@export var energy_max: float = 2.2
@export var flicker_speed: float = 5.5
@export var shake_strength: float = 0.03
@export var float_speed: float = 1.6
@export var float_amplitude: float = 0.12

var _time: float = 0.0
var _base_light_position: Vector3 = Vector3.ZERO
var _current_energy: float = 0.0
var _target_energy: float = 0.0
var _initial_y: float = 0.0


func _ready() -> void:
	randomize()
	_initial_y = position.y

	if is_instance_valid(light_node):
		_base_light_position = light_node.position
		_target_energy = randf_range(_safe_min_energy(), _safe_max_energy())
		_current_energy = _target_energy
		light_node.light_energy = _current_energy

	if is_instance_valid(particle_node):
		particle_node.emitting = true


func _process(delta: float) -> void:
	var elapsed_time: float = Time.get_ticks_msec() * 0.001
	position.y = _initial_y + sin(elapsed_time * float_speed) * float_amplitude

	if not is_instance_valid(light_node):
		return

	_time = elapsed_time * max(flicker_speed, 0.01)

	if absf(_target_energy - _current_energy) < 0.03:
		_target_energy = randf_range(_safe_min_energy(), _safe_max_energy())

	# Mezcla una onda suave con un objetivo aleatorio para un fuego más orgánico.
	var wave: float = sin(_time * 1.7) * 0.08
	var desired_energy: float = _target_energy + wave
	_current_energy = lerpf(_current_energy, desired_energy, clampf(delta * 8.0, 0.0, 1.0))
	_current_energy = clampf(_current_energy, _safe_min_energy(), _safe_max_energy())
	light_node.light_energy = _current_energy

	var jitter_x: float = sin(_time * 2.3 + randf() * 0.4) * shake_strength
	var jitter_z: float = cos(_time * 2.0 + randf() * 0.4) * shake_strength
	light_node.position = _base_light_position + Vector3(jitter_x, 0.0, jitter_z)

	if is_instance_valid(particle_node):
		var ratio: float = inverse_lerp(_safe_min_energy(), _safe_max_energy(), _current_energy)
		particle_node.speed_scale = lerpf(0.9, 1.1, ratio)


func _safe_min_energy() -> float:
	return minf(energy_min, energy_max)


func _safe_max_energy() -> float:
	return maxf(energy_min, energy_max)
