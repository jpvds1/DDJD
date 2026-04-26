extends Area3D


const BOOST = 5


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	# boost the player in the direction orthogonal to the ring
	body.position += BOOST * global_transform.basis.y
