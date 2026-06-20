extends Node3D

# ---------------------------------------------------------
# Node references
# ---------------------------------------------------------

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var stats: Node = %StatsManager
@onready var jump_audio_player: AudioStreamPlayer = $SFX/Jump

# ---------------------------------------------------------
# Variables
# ---------------------------------------------------------

var _player: CharacterBody3D
var _fall_blend := 0.0

@export var blend_strength := 20.0

# ---------------------------------------------------------
# Methods
# ---------------------------------------------------------

func _on_jumped(jump_number: int) -> void:
	_fall_blend = 0.8
	
	# play the 
	jump_audio_player.pitch_scale = 1.0 + float(jump_number) * 0.1  
	jump_audio_player.play()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_player = get_parent() as CharacterBody3D
	
	# connect to the jump event
	_player.jumped.connect(_on_jumped)


func _physics_process(delta: float) -> void:
	var lerp_weight := blend_strength * delta
	
	# compute the fall blending value
	var is_airborne := not is_zero_approx(_player.velocity.y)
	_fall_blend = lerp(
		_fall_blend,
		float(is_airborne),
		lerp_weight
	)

	# compute the movement blending value
	var max_sprint_speed: float = stats.sprint_speed.get_val()
	var local_velocity := _player.global_transform.basis.inverse() * _player.velocity
	var movement_blend := Vector2(local_velocity.x, -local_velocity.z) / max_sprint_speed
	
	# update the blending values
	animation_tree.set("parameters/Fall/blend_amount", _fall_blend)
	animation_tree.set("parameters/Movement/blend_position", movement_blend)
