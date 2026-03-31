extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var retract_timer: Timer = $RetractTimer

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		animation_player.play("out")
		retract_timer.start()

func _on_retract_timer_timeout() -> void:
	animation_player.play("hidden")
