extends Node3D

# ---------------------------------------------------------
# Exports
# ---------------------------------------------------------        

@export var player_path: NodePath
@export var ui_path: NodePath

# ---------------------------------------------------------
# Constants
# ---------------------------------------------------------        

const MAX_LIVES := 3

# ---------------------------------------------------------
# Runtime vars
# ---------------------------------------------------------        

var player: Node = null
var ui: Node = null

var run_time := 0.0
var timer_running := true
var level_completed := false
var is_paused := false

var lives := MAX_LIVES
var current_checkpoint_position := Vector3.ZERO
var has_checkpoint := false

var level_name := ""

# ---------------------------------------------------------
# Signals
# ---------------------------------------------------------        

signal lives_changed(current_lives: int, max_lives: int)
signal checkpoint_reached()
signal player_unalived()
signal run_completed(final_time: String)
signal pause_toggled(paused: bool)

# ---------------------------------------------------------
# Setup
# ---------------------------------------------------------        

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	player = get_node_or_null(player_path)
	ui = get_node_or_null(ui_path)
	
	if player == null:
		push_error("Level: player not found.")
		return
		
	if ui == null:
		push_error("Level: UI not found.")
		return
		
	level_name = scene_file_path.get_file().get_basename()
		
	player.unalive_requested.connect(_on_player_unalive_requested)
	player.checkpoint_requested.connect(_on_player_checkpoint_requested)
	player.finish_requested.connect(_on_player_finish_requested)
			
	run_time = 0.0
	timer_running = true
	level_completed = false
	is_paused = false
	
	lives = MAX_LIVES
	current_checkpoint_position = player.global_position
	has_checkpoint = true
	
	lives_changed.emit(lives, MAX_LIVES)
	_update_ui_timer()

	if player.has_method("start_recording"):
		player.start_recording()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()

func _process(delta: float) -> void:
	if not timer_running:
		return
		
	if is_paused:
		return
				
	run_time += delta
	_update_ui_timer()
	
# ---------------------------------------------------------
# Player signal handling
# ---------------------------------------------------------        

func _on_player_unalive_requested() -> void:
	if level_completed:
		return
		
	lives = max(lives -1, 0)
	player_unalived.emit()
	lives_changed.emit(lives, MAX_LIVES)
	
	respawn_player()
	
func _on_player_checkpoint_requested(pos: Vector3) -> void:
	if level_completed:
		return
		
	current_checkpoint_position = pos
	has_checkpoint = true
	checkpoint_reached.emit()
	
func _on_player_finish_requested() -> void:
	if level_completed:
		return
		
	level_completed = true
	timer_running = false
	
	var ghost_run_data: Array[Dictionary] = []
	if player.has_method("stop_recording"):
		ghost_run_data = player.stop_recording()
	
	player.lock_controls()
	
	var final_time := _format_time(run_time)
	_update_ui_timer()
	run_completed.emit(final_time)
	
	_handle_local_ghost_save(ghost_run_data)
	
	if Supabase.is_logged_in():
		var level_name_clean = scene_file_path.get_file().get_basename()
		await Supabase.submit_score(level_name_clean, int(run_time * 1000))
	
# ---------------------------------------------------------
# Pause control
# ---------------------------------------------------------        
	
func _toggle_pause() -> void:
	if level_completed:
		return
		
	_set_paused(not is_paused)
	
func _set_paused(should_pause: bool) -> void:
	if level_completed:
		return
		
	is_paused = should_pause
	
	if is_paused:
		player.lock_controls()
		player.pause_timers()
	else:
		player.unlock_controls()
		player.resume_timers()
		
	get_tree().paused = is_paused
	pause_toggled.emit(is_paused)
	
func resume_game() -> void:
	_set_paused(false)
	
func restart_level() -> void:
	get_tree().paused = false
	is_paused = false
	
	if Global.game_controller:
		Global.game_controller.change_3D_scene(scene_file_path)
	
func return_to_menu() -> void:
	get_tree().paused = false
	is_paused = false
	
	if Global.game_controller:
		Global.game_controller.change_GUI_scene("res://scenes/ui/main_menu.tscn")
	
# ---------------------------------------------------------
# Level actions
# ---------------------------------------------------------        
	
func respawn_player() -> void:
	if not has_checkpoint:
		return
		
	player.respawn_at(current_checkpoint_position)
	
# ---------------------------------------------------------
# UI
# ---------------------------------------------------------        
	
func _update_ui_timer() -> void:
	if ui:
		ui.set_timer_text(_format_time(run_time))
		
func _format_time(seconds: float) -> String:
	var total_ms := int(round(seconds * 1000.0))
	var minutes := total_ms / 60000
	var secs := (total_ms % 60000) / 1000
	var ms := total_ms % 1000
	
	return "%02d:%02d.%03d" % [minutes, secs, ms]

# ---------------------------------------------------------
# Ghost Storage Management (Offline/Local)
# ---------------------------------------------------------

func _handle_local_ghost_save(data: Array[Dictionary]) -> void:
	if data.is_empty():
		return
		
	var pb_path = "user://pb_time_" + level_name + ".txt"
	var current_pb := INF
	
	if FileAccess.file_exists(pb_path):
		var pb_file = FileAccess.open(pb_path, FileAccess.READ)
		if pb_file:
			current_pb = pb_file.get_as_text().to_float()
			pb_file.close()
			
	if run_time < current_pb:
		var pb_file_write = FileAccess.open(pb_path, FileAccess.WRITE)
		if pb_file_write:
			pb_file_write.store_string(str(run_time))
			pb_file_write.close()
			
		var ghost_path = "user://ghost_" + level_name + ".dat"
		var ghost_file = FileAccess.open(ghost_path, FileAccess.WRITE)
		if ghost_file:
			ghost_file.store_var(data)
			ghost_file.close()
