@tool
extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var laser_timer: Timer = $Timers/LaserTimer
@onready var idle_timer: Timer = $Timers/IdleTimer

## The duration in seconds of the laser shooting animation.
@export var laser_duration := 2.5 # seconds
## The amount of time in seconds the laser remains idle after shooting.
@export var idle_duration := 2.5 # seconds
## Whether the laser is shooting or not.
@export var active := true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if laser_duration == 0:
		return
		
	laser_timer.wait_time = laser_duration
	idle_timer.wait_time = idle_duration
	
	var timer := laser_timer if active else idle_timer
	timer.start()


func _on_laser_timer_timeout() -> void:
	animation_player.play("off")
	idle_timer.start()


func _on_idle_timer_timeout() -> void:
	animation_player.play("on")
	laser_timer.start()
