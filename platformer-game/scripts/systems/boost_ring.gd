extends Area3D

@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

@export var boost_speed: float = 20
@export var bidirectional: bool = false
@export var control_lock_duration: float = 1.0


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
		
	var ring_forward := global_transform.basis.y
	var is_going_forward = body.velocity.dot(ring_forward) >= 0.0

	# boost the player in the direction orthogonal to the ring
	var launch_dir := ring_forward * (1 if is_going_forward or not bidirectional else -1)
	#body.position = position
	body.apply_boost(launch_dir * boost_speed, control_lock_duration)
	
	# play the sound effect
	audio_player.play()
