extends Node3D

# ---------------------------------------------------------
# Constants
# ---------------------------------------------------------		

@export var player_path: NodePath
@export var ui_path: NodePath

const MAX_LIVES := 3

# ---------------------------------------------------------
# Runtime vars
# ---------------------------------------------------------		

var player: Node = null
var ui: Node = null

var run_time := 0.0
var timer_running := true
var level_completed := false

var lives := MAX_LIVES
var current_checkpoint_position := Vector3.ZERO
var has_checkpoint := false

# ---------------------------------------------------------
# Signals
# ---------------------------------------------------------		

signal lives_changed(current_lives: int, max_lives: int)
signal checkpoint_reached()
signal player_unalived()
signal run_completed(final_time: String)

# ---------------------------------------------------------
# Setup
# ---------------------------------------------------------		

func _ready() -> void:
	player = get_node_or_null(player_path)
	ui = get_node_or_null(ui_path)
	
	if player == null:
		push_error("Level: player not found.")
		return
		
	if ui == null:
		push_error("Level: UI not found.")
		return
		
	player.unalive_requested.connect(_on_player_unalive_requested)
	player.checkpoint_requested.connect(_on_player_checkpoint_requested)
	player.finish_requested.connect(_on_player_finish_requested)
			
	run_time = 0.0
	timer_running = true
	level_completed = false
	
	lives = MAX_LIVES
	current_checkpoint_position = player.global_position
	has_checkpoint = false
	
	lives_changed.emit(lives, MAX_LIVES)
	_update_ui_timer()


func _process(delta: float) -> void:
	if not timer_running:
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
	
	player.lock_controls()
	
	var final_time := _format_time(run_time)
	_update_ui_timer()
	run_completed.emit(final_time)
	
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
	
	return "%02d:%02d:%03d" % [minutes, secs, ms]
