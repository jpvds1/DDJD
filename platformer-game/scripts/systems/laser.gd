@tool
extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var laser_timer: Timer = $Timers/LaserTimer
@onready var idle_timer: Timer = $Timers/IdleTimer

## Whether the laser is operational.
@export var active := true:
	set(value):
		active = value
		if is_node_ready():
			_update_laser()
## The duration in seconds of the laser shooting animation.
@export var laser_duration := 2.5 # seconds
## The amount of time in seconds the laser remains idle after shooting.
@export var idle_duration := 2.5 # seconds


func _update_laser() -> void:
	# reset the timers
	laser_timer.stop()
	idle_timer.stop()
	
	if active:
		# fire the laser
		_on_idle_timer_timeout()
	else:
		animation_player.play("off")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	laser_timer.wait_time = laser_duration
	idle_timer.wait_time = idle_duration
	
	_update_laser()


func _on_laser_timer_timeout() -> void:
	animation_player.play("off")
	idle_timer.start()


func _on_idle_timer_timeout() -> void:
	animation_player.play("on")
	laser_timer.start()
