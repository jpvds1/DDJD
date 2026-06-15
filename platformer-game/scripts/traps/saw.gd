extends Node3D

@export var rotations_per_second := 0.5
@onready var animation_player: AnimationPlayer = $AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player.speed_scale = rotations_per_second
