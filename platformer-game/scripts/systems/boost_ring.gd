extends Area3D


const BOOST = 5.0
const NORMAL = Vector3(0, 1, 0)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	
	var direction = Vector3(0, 1, 0).rotated(Vector3(1, 0, 0), rotation.x) \
		.rotated(Vector3(0, 1, 0), rotation.y) \
		.rotated(Vector3(0, 0, 1), rotation.z) \
		.normalized()
	
	print(body.position)
	body.position += BOOST * direction
	print(body.position)
