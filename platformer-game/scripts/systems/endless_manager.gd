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

# ---------------------------------------------------------
# Constants
# ---------------------------------------------------------        
const MAX_LIVES := 3

# ---------------------------------------------------------
# 1. State Variables (Run Control)
# ---------------------------------------------------------        
var player: Node = null
var ui: Node = null

var lives := MAX_LIVES
var distance := 0
var is_paused := false
var game_over_triggered := false

# ---------------------------------------------------------
# Setup
# ---------------------------------------------------------        
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	player = get_node_or_null(player_path)
	ui = get_node_or_null(ui_path)
	
	if player == null:
		push_error("EndlessManager: Player node not found.")
		return
		
	lives_changed.emit(lives, MAX_LIVES)

# ---------------------------------------------------------
# 2. Pause System
# ---------------------------------------------------------        
func _unhandled_input(event: InputEvent) -> void:
	if game_over_triggered:
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
		if player.has_method("lock_controls"):
			player.lock_controls()
		if player.has_method("pause_timers"):
			player.pause_timers()
	else:
		if player.has_method("unlock_controls"):
			player.unlock_controls()
		if player.has_method("resume_timers"):
			player.resume_timers()
			
	get_tree().paused = is_paused
	pause_toggled.emit(is_paused)

# ---------------------------------------------------------
# UI Duck-Typing Interface (Main_UI Button Flow)
# ---------------------------------------------------------        
func is_endless() -> bool:
	return true

func resume_game() -> void:
	_set_paused(false)

func restart_level() -> void:
	get_tree().paused = false
	is_paused = false
	Global.game_controller.change_3D_scene("res://scenes/levels/endless_level.tscn")
	
func return_to_menu() -> void:
	get_tree().paused = false
	is_paused = false
	Global.game_controller.change_GUI_scene("res://scenes/ui/main_menu.tscn")
