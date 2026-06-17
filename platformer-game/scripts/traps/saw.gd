extends Node3D

@export var rotations_per_second := 0.5
@onready var visuals: Node3D = $Visuals

var rotation_speed := rotations_per_second * 2 * PI # radians per second


func _physics_process(delta: float) -> void:
	visuals.rotate_z(rotation_speed * delta)
