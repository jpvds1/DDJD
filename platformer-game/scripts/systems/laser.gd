extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer

var active := true

func _on_timer_timeout() -> void:
	if active:
		animation_player.play("off")
	else:
		animation_player.play("on")
		
	active = !active
	timer.start()
