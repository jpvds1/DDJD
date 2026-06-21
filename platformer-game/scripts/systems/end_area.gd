extends Area3D

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.request_finish()
		audio_player.play()
