extends Node3D

# ---------------------------------------------------------
# Exports
# ---------------------------------------------------------        

@export var player_path: NodePath
@export var ui_path: NodePath
@export var ghost_scene: PackedScene = preload("res://scenes/player/ghost_character.tscn")

@export_group("Gear Reward")
@export var gear_unlock_on_complete: GearItem = null

@export_group("Star Times")
@export var time_3_stars: float = 60.0
@export var time_2_stars: float = 90.0
@export var time_1_star: float = 120.0

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
var game_over_triggered := false
var is_paused := false

var lives := MAX_LIVES
var current_checkpoint_position := Vector3.ZERO
var has_checkpoint := false

var level_name := ""

# Achievements
var extra_jumps_used := false
var died_this_run := false

# ---------------------------------------------------------
# Signals
# ---------------------------------------------------------        

signal lives_changed(current_lives: int, max_lives: int)
signal checkpoint_reached()
signal player_unalived()
signal game_over()
signal run_completed(final_time: String, stars: int)
signal pause_toggled(paused: bool)

# ---------------------------------------------------------
# Setup
# ---------------------------------------------------------        

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AchievementManager.level_done = false

	player = get_node_or_null(player_path)
	ui = get_node_or_null(ui_path)

	if player == null or ui == null:
		push_error("Level: Player or UI not found.")
		return
		
	level_name = scene_file_path.get_file().get_basename()
	
	player.get_node("Visuals/AudioListener3D").current = true
	player.unalive_requested.connect(_on_player_unalive_requested)
	player.checkpoint_requested.connect(_on_player_checkpoint_requested)
	player.finish_requested.connect(_on_player_finish_requested)
	player.connect("extra_jumps_changed", _on_extra_jumps_changed)
			
	run_time = 0.0
	timer_running = true
	level_completed = false
	game_over_triggered = false
	is_paused = false
	extra_jumps_used = false
	died_this_run = false
	
	lives = MAX_LIVES
	current_checkpoint_position = player.global_position
	has_checkpoint = true
	
	lives_changed.emit(lives, MAX_LIVES)
	_update_ui_timer()

	_check_and_spawn_ghost()

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
	if level_completed or game_over_triggered:
		return

	died_this_run = true
	lives = max(lives - 1, 0)
	player_unalived.emit()
	lives_changed.emit(lives, MAX_LIVES)

	if lives == 0:
		game_over_triggered = true
		timer_running = false
		player.lock_controls()
		game_over.emit()
	else:
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
	
	var stars = _calculate_stars()
	
	var level_id = scene_file_path.get_file().get_basename()
	
	GlobalInventory.complete_level(level_id, gear_unlock_on_complete)
	GlobalInventory.award_stars(level_id, stars)
	AchievementManager.check_level_completion_achievements(extra_jumps_used, died_this_run)
	
	run_completed.emit(final_time, stars)
	
	_handle_local_ghost_save(ghost_run_data)
	
	if Supabase.is_logged_in():
		await Supabase.submit_score(level_id, int(run_time * 1000))

func _on_extra_jumps_changed(current: int, max_jumps: int) -> void:
	if current < max_jumps:
		extra_jumps_used = true
	
# ---------------------------------------------------------
# Level control
# ---------------------------------------------------------		

func _calculate_stars() -> int:
	if time_3_stars > 0.0 and run_time <= time_3_stars:
		return 3
	if time_2_stars > 0.0 and run_time <= time_2_stars:
		return 2
	if time_1_star > 0.0 and run_time <= time_1_star:
		return 1
	return 0

# ---------------------------------------------------------
# Pause control
# ---------------------------------------------------------        
	
func _toggle_pause() -> void:
	if level_completed or game_over_triggered:
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

const SAVES_PATH = "user://saves.dat"

func _load_saves() -> Dictionary:
	if not FileAccess.file_exists(SAVES_PATH):
		return {}
	var f = FileAccess.open(SAVES_PATH, FileAccess.READ)
	if f:
		var data = f.get_var()
		f.close()
		if data is Dictionary:
			return data
	return {}

func _write_saves(saves: Dictionary) -> void:
	var f = FileAccess.open(SAVES_PATH, FileAccess.WRITE)
	if f:
		f.store_var(saves)
		f.close()

func _handle_local_ghost_save(data: Array[Dictionary]) -> void:
	if data.is_empty():
		return

	var saves = _load_saves()
	var entry: Dictionary = saves.get(level_name, {})
	var current_pb: float = entry.get("pb", INF)

	if run_time < current_pb:
		entry["pb"] = run_time
		entry["ghost"] = data
		saves[level_name] = entry
		_write_saves(saves)

func _check_and_spawn_ghost() -> void:
	if not SettingsManager.ghost_replay:
		return

	var entry: Dictionary = _load_saves().get(level_name, {})
	var loaded_data = entry.get("ghost", [])
	if loaded_data is Array and not loaded_data.is_empty():
		var ghost_instance = ghost_scene.instantiate()
		add_child(ghost_instance)
		if ghost_instance.has_method("start_replay"):
			ghost_instance.start_replay(loaded_data)
