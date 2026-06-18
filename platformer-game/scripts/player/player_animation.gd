extends Node3D

# ---------------------------------------------------------
# Node references
# ---------------------------------------------------------

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var stats: Node = %StatsManager

# ---------------------------------------------------------
# Variables
# ---------------------------------------------------------

var _player: CharacterBody3D
var _fall_blend := 0.0
var _slide_blend := 0.0

@export var blend_strength := 15.0

# ---------------------------------------------------------
# Methods
# ---------------------------------------------------------

func _on_extra_jumps_changed(current_extra_jumps: int, max_extra_jumps: int) -> void:
	if current_extra_jumps < max_extra_jumps:
		_fall_blend = 0.8

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_player = get_parent() as CharacterBody3D
	
	# connect to the jump event
	_player.extra_jumps_changed.connect(_on_extra_jumps_changed)

func _physics_process(delta: float) -> void:
	var lerp_weight := blend_strength * delta

	# compute the movement blending value
	var max_sprint_speed: float = stats.sprint_speed.get_val()
	var local_velocity := _player.global_transform.basis.inverse() * _player.velocity
	var movement_blend := Vector2(local_velocity.x, -local_velocity.z) / max_sprint_speed
	
	# compute the slide blending value
	_slide_blend = lerp(
		_slide_blend,
		float(_player.is_sliding),
		lerp_weight
	)

	# compute the fall blending value
	var is_airborne := !is_zero_approx(_player.velocity.y)
	_fall_blend = lerp(
		_fall_blend,
		float(is_airborne),
		lerp_weight
	)

	# update the blending values
	animation_tree.set("parameters/Movement/blend_position", movement_blend)
	animation_tree.set("parameters/Slide/blend_amount", _slide_blend)
	animation_tree.set("parameters/Fall/blend_amount", _fall_blend)
