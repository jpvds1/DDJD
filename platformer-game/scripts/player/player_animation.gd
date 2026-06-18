extends Node3D

# ---------------------------------------------------------
# Node references
# ---------------------------------------------------------

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var stats: Node = %StatsManager

# ---------------------------------------------------------
# Variables
# ---------------------------------------------------------

@export var blend_strength := 15.0

var player: CharacterBody3D
var fall_blend := 0.0

# ---------------------------------------------------------
# Methods
# ---------------------------------------------------------

func update_blend_values(movement: Vector2, jump: float) -> void:
	animation_tree.set("parameters/Movement/blend_position", blend_strength * movement)
	animation_tree.set("parameters/Jump/blend_amount", blend_strength * jump)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_parent() as CharacterBody3D

func _physics_process(delta: float) -> void:
	var max_sprint_speed: float = stats.sprint_speed.get_val()
	var local_velocity := player.global_transform.basis.inverse() * player.velocity
	var lerp_weight := blend_strength * delta
	
	# compute the fall blending value
	fall_blend = lerp(
		fall_blend,
		float(player.is_on_floor()),
		lerp_weight
	)

	# compute the movement blending value
	var movement_blend := Vector2(local_velocity.x, -local_velocity.z) / max_sprint_speed
	
	# update the blending values
	animation_tree.set("parameters/Fall/blend_amount", fall_blend)
	animation_tree.set("parameters/Movement/blend_position", movement_blend)
