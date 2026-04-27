extends Area3D


@export var boost = 12


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
		
	# detect if the player is entering the ring from the front or behind
	var normal = global_transform.basis.y
	var angle = body.velocity.angle_to(normal)

	# boost the player in the direction orthogonal to the ring
	body.velocity += boost * normal * (1 if angle <= PI / 2 else -1)
