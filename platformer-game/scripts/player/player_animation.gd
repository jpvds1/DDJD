extends Node3D

# ---------------------------------------------------------
# Node references
# ---------------------------------------------------------

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var stats: Node = %StatsManager

# audio players
@onready var movement_audio_player: AudioStreamPlayer = $SFX/Move
@onready var jump_audio_player: AudioStreamPlayer = $SFX/Jump
@onready var dash_audio_player: AudioStreamPlayer = $SFX/Dash
@onready var land_audio_player: AudioStreamPlayer = $SFX/Land

# ---------------------------------------------------------
# Variables
# ---------------------------------------------------------

var _player: CharacterBody3D
var _was_airborne := false

# blending values
var _fall_blend := 0.0
var _movement_blend: Vector2

@export var blend_strength := 20.0

# ---------------------------------------------------------
# Methods
# ---------------------------------------------------------

func _on_jumped(jump_number: int) -> void:
	_fall_blend = 0.8
	
	# play the jump audio
	jump_audio_player.pitch_scale = 1.0 + float(jump_number) * 0.1  
	jump_audio_player.play()


func _on_dashed() -> void:
	# play the dash audio
	dash_audio_player.play()


func _update_animations(delta: float) -> void:
	var lerp_weight := blend_strength * delta

	# compute the movement blending value
	var max_sprint_speed: float = stats.sprint_speed.get_val()
	var local_velocity := _player.global_transform.basis.inverse() * _player.velocity
	_movement_blend = Vector2(local_velocity.x, -local_velocity.z) / max_sprint_speed

	# compute the fall blending value	
	var is_airborne := not is_zero_approx(_player.velocity.y)
	_fall_blend = lerp(
		_fall_blend,
		float(is_airborne),
		lerp_weight
	)

	# update the blending values
	animation_tree.set("parameters/Fall/blend_amount", _fall_blend)
	animation_tree.set("parameters/Movement/blend_position", _movement_blend)


func _update_sound_effects() -> void:
	var is_grounded = is_zero_approx(_player.velocity.y)
	var is_moving = is_grounded and _movement_blend.length() > 0
	
	# play the landing sound
	if _was_airborne and is_grounded:
		land_audio_player.play()
	# play the movement sound
	elif is_moving and not movement_audio_player.playing:
		movement_audio_player.pitch_scale = 1.0 + _movement_blend.length() * 0.1
		movement_audio_player.play()

	_was_airborne = not is_grounded


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_player = get_parent() as CharacterBody3D
	_was_airborne = not is_zero_approx(_player.velocity.y)
	
	# connect to the player events
	_player.jumped.connect(_on_jumped)
	_player.dashed.connect(_on_dashed)


func _physics_process(delta: float) -> void:
	_update_animations(delta)
	_update_sound_effects()
