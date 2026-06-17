extends Node3D

# ---------------------------------------------------------
# Node references
# ---------------------------------------------------------

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var stats: Node = %StatsManager

# ---------------------------------------------------------
# Variables
# ---------------------------------------------------------

@export var blend_strength: int = 1
var player: CharacterBody3D


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
	var is_jumping = player.velocity.y > 0
	var max_sprint_speed: float = stats.sprint_speed.get_val()
	var movement_blend := Vector2(
		player.velocity.x,
		player.velocity.z
	) / max_sprint_speed
	
	update_blend_values(movement_blend, int(is_jumping))	
