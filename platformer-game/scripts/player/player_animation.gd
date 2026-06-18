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

@export var blend_strength := 20.0

# ---------------------------------------------------------
# Methods
# ---------------------------------------------------------

func _on_player_jumped() -> void:
	_fall_blend = 0.8

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_player = get_parent() as CharacterBody3D
	
	# connect to the jump event
	_player.jumped.connect(_on_player_jumped)

func _physics_process(delta: float) -> void:
	var max_sprint_speed: float = stats.sprint_speed.get_val()
	var local_velocity := _player.global_transform.basis.inverse() * _player.velocity
	var lerp_weight := blend_strength * delta
	
	# compute the fall blending value
	_fall_blend = lerp(
		_fall_blend,
		float(_player.is_on_floor() or _player.is_on_wall()),
		lerp_weight
	)

	# compute the movement blending value
	var movement_blend := Vector2(local_velocity.x, -local_velocity.z) / max_sprint_speed
	
	# update the blending values
	animation_tree.set("parameters/Fall/blend_amount", _fall_blend)
	animation_tree.set("parameters/Movement/blend_position", movement_blend)
