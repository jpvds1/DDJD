extends Area3D


@export var boost: float = 12
@export var bidirectional = false


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
		
	# detect if the player is entering the ring from the front or behind
	var normal = global_transform.basis.y
	var angle = body.velocity.angle_to(normal)
	var multiplier = -1 if bidirectional and angle > PI / 2 else 1

	# boost the player in the direction orthogonal to the ring
	body.velocity += boost * multiplier * normal
