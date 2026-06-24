extends Node3D

# ---------------------------------------------------------
# Node references
# ---------------------------------------------------------

const SILENCE := -80.0
const MOVEMENT_AUDIO_VOLUME := -10.0 

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var stats: Node = %StatsManager

# audio players
@onready var movement_audio_player: AudioStreamPlayer = $SFX/Move
@onready var jump_audio_player: AudioStreamPlayer = $SFX/Jump
@onready var dash_audio_player: AudioStreamPlayer = $SFX/Dash
@onready var land_audio_player: AudioStreamPlayer = $SFX/Land
@onready var death_audio_player: AudioStreamPlayer = $SFX/Death

# ---------------------------------------------------------
# Variables
# ---------------------------------------------------------

var _player: CharacterBody3D
var _was_airborne := false

# blend balues
var _fall_blend := 0.0
var _dash_blend := 0.0

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
	

func _on_death() -> void:
	# play the death audio
	death_audio_player.play()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_player = get_parent() as CharacterBody3D
	_was_airborne = _player.is_airborne()
	
	# connect to the player events
	_player.jumped.connect(_on_jumped)
	_player.dashed.connect(_on_dashed)
	_player.unalive_requested.connect(_on_death)


func _physics_process(delta: float) -> void:
	var lerp_weight := blend_strength * delta

	# compute the movement blending value
	var max_sprint_speed: float = stats.sprint_speed.get_val()
	var local_velocity := _player.global_transform.basis.inverse() * _player.velocity
	var movement_blend := Vector2(local_velocity.x, -local_velocity.z) / max_sprint_speed

	# compute the fall blending value	
	var is_airborne: bool = _player.is_airborne()
	_fall_blend = lerp(
		_fall_blend,
		float(is_airborne),
		lerp_weight
	)

	if _was_airborne and not is_airborne:
		land_audio_player.play()

	_was_airborne = is_airborne

	# compute the dash blending value
	_dash_blend = lerp(
		_dash_blend,
		float(_player.is_dashing),
		lerp_weight
	)
	
	# update the blending values
	animation_tree.set("parameters/Movement/blend_position", movement_blend)
	animation_tree.set("parameters/Fall/blend_amount", _fall_blend)
	animation_tree.set("parameters/Dash/blend_amount", _dash_blend)
	
	# silence the movement sound if needed
	movement_audio_player.volume_db = SILENCE if is_airborne else MOVEMENT_AUDIO_VOLUME 
