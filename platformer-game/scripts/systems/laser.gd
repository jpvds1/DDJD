@tool
extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var laser_timer: Timer = $Timers/LaserTimer
@onready var idle_timer: Timer = $Timers/IdleTimer
@onready var delay_timer: Timer = $Timers/DelayTimer

## Whether the laser is operational.
@export var active := true:
	set(value):
		active = value
		if is_node_ready():
			_start_laser()
## The duration in seconds of the laser shooting animation.
@export var laser_duration := 2.5: # seconds
	set(value):
		laser_duration = max(0, value)
## The amount of time in seconds the laser remains idle after shooting.
@export var idle_duration := 2.5: # seconds
	set(value):
		idle_duration = max(0, value)
## The amount of time in seconds the laser remains idle after shooting.
@export var delay := 0.0: # seconds
	set(value):
		delay = max(0, value)


func _update_laser() -> void:
	if active:
		# fire the laser
		_on_idle_timer_timeout()
	else:
		animation_player.play("off")


func _start_laser() -> void:
	# reset the timers
	laser_timer.stop()
	idle_timer.stop()
	delay_timer.stop()
	
	if delay > 0:
		delay_timer.start(delay)
	else:
		_update_laser()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_start_laser()


func _on_delay_timer_timeout() -> void:
	_update_laser()


func _on_laser_timer_timeout() -> void:
	animation_player.play("off")
	idle_timer.start(idle_duration)


func _on_idle_timer_timeout() -> void:
	animation_player.play("on")
	laser_timer.start(laser_duration)
