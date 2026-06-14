extends Node3D

# ---------------------------------------------------------
# Signals
# ---------------------------------------------------------        
signal lives_changed(current_lives: int, max_lives: int)
signal player_unalived()
signal run_completed(final_distance: String)
signal pause_toggled(paused: bool)
signal checkpoint_reached()

# ---------------------------------------------------------
# Exports
# ---------------------------------------------------------        
@export var player_path: NodePath
@export var ui_path: NodePath
@export var chunk_scenes: Array[PackedScene] = []

# ---------------------------------------------------------
# Constants
# ---------------------------------------------------------        
const MAX_LIVES := 3
const CHUNK_DESPAWN_DISTANCE := 50.0

# ---------------------------------------------------------
# State Variables
# ---------------------------------------------------------        
var player: CharacterBody3D = null
var ui: CanvasLayer = null

var lives := MAX_LIVES
var distance := 0
var is_paused := false
var game_over_triggered := false

var active_chunks: Array[Node3D] = []
var next_spawn_position := Vector3.ZERO
var max_visible_chunks := 5
var start_track_axis_z := 0.0

# ---------------------------------------------------------
# Setup
# ---------------------------------------------------------        
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	player = get_node_or_null(player_path) as CharacterBody3D
	ui = get_node_or_null(ui_path) as CanvasLayer
	
	if player == null:
		push_error("EndlessManager: Player node not found.")
		return
		
	if chunk_scenes.is_empty():
		push_error("EndlessManager: No chunks assigned in the chunk_scenes array!")
		return
		
	start_track_axis_z = player.global_position.z # Track Z axis
	
	for i in range(max_visible_chunks):
		_spawn_random_chunk()
		
	lives_changed.emit(lives, MAX_LIVES)

func _physics_process(_delta: float) -> void:
	if game_over_triggered or player == null:
		return
		
	_track_distance()
	_check_chunk_recycling()

# ---------------------------------------------------------
# Phase 3 Core Algorithmic Functions (Z- Adaptations)
# ---------------------------------------------------------        

func _spawn_random_chunk() -> void:
	var random_index := randi() % chunk_scenes.size()
	var chunk_instance = chunk_scenes[random_index].instantiate() as Node3D
	
	add_child(chunk_instance)
	active_chunks.append(chunk_instance)
	
	chunk_instance.global_position = next_spawn_position
	
	var exit_marker = chunk_instance.get_node_or_null("ExitMarker") as Marker3D
	if exit_marker:
		next_spawn_position += Vector3(0, 0, exit_marker.position.z)
	else:
		next_spawn_position += Vector3(0, 0, -30.0)

func _track_distance() -> void:
	var current_distance = int(abs(player.global_position.z - start_track_axis_z))
	
	if current_distance > distance:
		distance = current_distance
		if ui and ui.has_method("set_timer_text"):
			ui.set_timer_text(str(distance) + "m")

func _check_chunk_recycling() -> void:
	if active_chunks.size() < 2:
		return
		
	var oldest_chunk = active_chunks[0]
	var next_chunk = active_chunks[1]
	
	if player.global_position.z < next_chunk.global_position.z - CHUNK_DESPAWN_DISTANCE:
		active_chunks.pop_front()
		oldest_chunk.queue_free()
		_spawn_random_chunk()

# ---------------------------------------------------------
# Player Hazard & Event Triggers
# ---------------------------------------------------------        

func trigger_damage() -> void:
	if game_over_triggered:
		return
		
	lives = max(lives - 1, 0)
	lives_changed.emit(lives, MAX_LIVES)
	player_unalived.emit()
	
	if lives <= 0:
		_trigger_game_over()
	else:
		_respawn_on_current_chunk()

func _respawn_on_current_chunk() -> void:
	if active_chunks.is_empty() or player == null:
		return
		
	var current_chunk = active_chunks[1] if active_chunks.size() > 1 else active_chunks[0]
	if player.has_method("respawn_at"):
		player.respawn_at(current_chunk.global_position + Vector3(0, 2.0, 0))

func _trigger_game_over() -> void:
	game_over_triggered = true
	if player.has_method("lock_controls"):
		player.lock_controls()
		
	run_completed.emit(str(distance) + "m")

# ---------------------------------------------------------
# Pause System (Maintained)
# ---------------------------------------------------------        
func _unhandled_input(event: InputEvent) -> void:
	if game_over_triggered or player == null:
		return
		
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()

func _toggle_pause() -> void:
	_set_paused(not is_paused)
	
func _set_paused(should_pause: bool) -> void:
	if game_over_triggered:
		return
		
	is_paused = should_pause
	
	if is_paused:
		if player.has_method("lock_controls"): player.lock_controls()
		if player.has_method("pause_timers"): player.pause_timers()
	else:
		if player.has_method("unlock_controls"): player.unlock_controls()
		if player.has_method("resume_timers"): player.resume_timers()
			
	get_tree().paused = is_paused
	pause_toggled.emit(is_paused)
	
# ---------------------------------------------------------
# UI Duck-Typing Interface (Main_UI Compatibility)
# ---------------------------------------------------------        
func is_endless() -> bool:
	return true

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
