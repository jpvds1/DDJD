extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var delay_timer: Timer = $DelayTimer


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not animation_player.is_playing():
		animation_player.play("out")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "out":
		delay_timer.start()


func _on_delay_timer_timeout() -> void:
	animation_player.play("hide")
