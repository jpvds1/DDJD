extends Node3D

var replay_data: Array = []
var current_frame := 0
var is_playing := false

@onready var animation_player: AnimationPlayer = $Node3D/Dash/AnimationPlayer

func start_replay(data: Array) -> void:
	if data.is_empty():
		return
	replay_data = data
	current_frame = 0
	is_playing = true
	visible = true

func _physics_process(_delta: float) -> void:
	if not is_playing or replay_data.is_empty():
		return
		
	if current_frame >= replay_data.size():
		is_playing = false
		return
		
	var snapshot = replay_data[current_frame]
	
	global_position = snapshot["p"]
	global_rotation.y = snapshot["r"]
	
	var anim_name = snapshot["a"]
	if anim_name != "" and animation_player:
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name)
			
	current_frame += 1
