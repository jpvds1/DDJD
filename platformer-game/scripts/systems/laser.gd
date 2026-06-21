@tool
extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var laser_timer: Timer = $Timers/LaserTimer
@onready var idle_timer: Timer = $Timers/IdleTimer
@onready var delay_timer: Timer = $Timers/DelayTimer

## Whether the laser is operational.
@export var active := true:
	set(value):
		active = value
		if is_node_ready():
			_setup_laser()
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


func _fire_laser() -> void:
	animation_player.play("on")
	audio_player.play()
	laser_timer.start(laser_duration)
	

func _stop_laser(restart: bool) -> void:
	animation_player.play("off")
	audio_player.stop()
	
	if restart:
		idle_timer.start(idle_duration)


func _update_laser() -> void:
	if active:
		_fire_laser()
	else:
		_stop_laser(false)


func _setup_laser() -> void:
	# reset the timers
	laser_timer.stop()
	idle_timer.stop()
	delay_timer.stop()
	
	# reset the audio player
	audio_player.stop()
	
	if delay > 0:
		delay_timer.start(delay)
	else:
		_update_laser()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_setup_laser()


func _on_delay_timer_timeout() -> void:
	_update_laser()


func _on_laser_timer_timeout() -> void:
	_stop_laser(true)


func _on_idle_timer_timeout() -> void:
	_fire_laser()
