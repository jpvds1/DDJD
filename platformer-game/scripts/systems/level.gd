extends Node3D

@export var player_path: NodePath
@export var ui_path: NodePath

var player: Node = null
var ui: Node = null

var run_time := 0.0
var timer_running := true

func _ready() -> void:
	player = get_node_or_null(player_path)
	ui = get_node_or_null(ui_path)
	
	if player == null:
		push_error("Level: player not found.")
		return
		
	if ui == null:
		push_error("Level: UI not found.")
		return
		
	player.end_reached.connect(_on_player_end_reached)
	
	run_time = 0.0
	timer_running = true
	_update_ui_timer()


func _process(delta: float) -> void:
	if not timer_running:
		return
				
	run_time += delta
	_update_ui_timer()
	
func _on_player_end_reached() -> void:
	timer_running = false
	_update_ui_timer()
	
func _update_ui_timer() -> void:
	if ui:
		ui.set_timer_text(_format_time(run_time))
		
func _format_time(seconds: float) -> String:
	var total_ms := int(round(seconds * 1000.0))
	var minutes := total_ms / 60000
	var secs := (total_ms % 60000) / 1000
	var ms := total_ms % 1000
	
	return "%02d:%02d:%03d" % [minutes, secs, ms]
