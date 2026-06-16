extends Area3D


@export var boost_speed: float = 20
@export var bidirectional = false
@export var control_lock_diration: float = 0.4


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
		
	var ring_forward := global_transform.basis.y.normalized()
	var entry_dot = body.velocity.dot(ring_forward)
	var launch_dir := ring_forward if entry_dot >= 0.0 else -ring_forward
	
	if not bidirectional and entry_dot < 0.0:
		return

	# boost the player in the direction orthogonal to the ring
	body.apply_boost(launch_dir * boost_speed, control_lock_diration)
