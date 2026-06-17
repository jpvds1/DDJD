extends CanvasLayer

@export var player_path: NodePath
@export var level_path: NodePath

# ---------------------------------------------------------
# UI components
# ---------------------------------------------------------

# HUD
@onready var lives_container: HBoxContainer = $HUD/RootMargin/MainVBox/LivesContainer
@onready var jumps_container: HBoxContainer = $HUD/RootMargin/MainVBox/JumpsContainer

@onready var dash_row: Control = $HUD/RootMargin/MainVBox/DashRow
@onready var dash_background: ColorRect = $HUD/RootMargin/MainVBox/DashRow/DashBackground
@onready var dash_fill: ColorRect = $HUD/RootMargin/MainVBox/DashRow/DashFill

@onready var message_label: Label = $HUD/MessageTop/MessageCenter/MessageLabel
@onready var timer_label: Label = $HUD/TimerMargin/TimerLabel

# Level finish
@onready var level_complete_overlay: Control = $LevelCompleteOverlay
@onready var time_label: Label = $LevelCompleteOverlay/CenterContainer/PanelContainer/VBoxContainer/TimeLabel
@onready var finish_restart_button: Button = $LevelCompleteOverlay/CenterContainer/PanelContainer/VBoxContainer/FinishRestartButton
@onready var finish_back_button: Button = $LevelCompleteOverlay/CenterContainer/PanelContainer/VBoxContainer/FinishBackButton

# Pause menu
@onready var pause_overlay: Control = $PauseOverlay
@onready var pause_resume_button: Button = $PauseOverlay/CenterContainer/PanelContainer/VBoxContainer/PauseResumeButton
@onready var pause_restart_button: Button = $PauseOverlay/CenterContainer/PanelContainer/VBoxContainer/PauseRestartButton
@onready var pause_back_button: Button = $PauseOverlay/CenterContainer/PanelContainer/VBoxContainer/PauseBackButton

var player: Node = null
var level: Node = null

# ---------------------------------------------------------
# Dash UI state
# ---------------------------------------------------------

var dash_cooldown_active := false
var dash_cooldown_duration := 0.0
var dash_cooldown_time_left := 0.0
var ui_paused := false

# ---------------------------------------------------------
# Setup
# ---------------------------------------------------------

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	player = get_node_or_null(player_path)
	level = get_node_or_null(level_path)
	
	if player == null:
		push_error("UI: player_path is not assigned or player was not found.")
		return
		
	if level == null:
		push_error("UI: level_path is not assigned or level was not found.")
		return
		
	# Player-driven UI
	player.extra_jumps_changed.connect(_on_extra_jumps_changed)
	player.dash_cooldown_started.connect(_on_dash_cooldown_started)
	player.dash_ready.connect(_on_dash_ready)
	
	# Level-driven UI
	level.lives_changed.connect(_on_lives_changed)
	level.checkpoint_reached.connect(_on_checkpoint_reached)
	level.player_unalived.connect(_on_player_unalived)
	level.run_completed.connect(_on_run_completed)
	level.pause_toggled.connect(_on_pause_toggled)
	
	# Finish overlay buttons
	finish_restart_button.pressed.connect(_on_finish_restart_button_pressed)
	finish_back_button.pressed.connect(_on_finish_back_button_pressed)
	
	# Pause overlay buttons
	pause_resume_button.pressed.connect(_on_pause_resume_button_pressed)
	pause_restart_button.pressed.connect(_on_pause_restart_button_pressed)
	pause_back_button.pressed.connect(_on_pause_back_button_pressed)
	
	message_label.visible = false
	level_complete_overlay.visible = false
	pause_overlay.visible = false
	
	if level and level.has_method("is_endless"):
		timer_label.text = "0m"
	
	player.emit_initial_ui_state()
	
func _process(delta: float) -> void:
	if ui_paused:
		return
	
	if dash_cooldown_active:
		dash_cooldown_time_left = max(dash_cooldown_time_left - delta, 0.0)
		
		var ratio = 1.0 - (dash_cooldown_time_left / dash_cooldown_duration)
		_set_dash_fill_ratio(ratio)
		
		if dash_cooldown_time_left <= 0.0:
			dash_cooldown_active = false
			_set_dash_fill_ratio(1.0)
	
# ---------------------------------------------------------
# Handle signals
# ---------------------------------------------------------	

func _on_lives_changed(current_lives: int, max_lives: int) -> void:
	_rebuild_boxes(lives_container, current_lives, max_lives)
	
func _on_extra_jumps_changed(current_extra_jumps: int, max_extra_jumps: int) -> void:
	_rebuild_boxes(jumps_container, current_extra_jumps, max_extra_jumps)
	
func _on_dash_cooldown_started(duration: float) -> void:
	dash_cooldown_duration = duration
	dash_cooldown_time_left = duration
	dash_cooldown_active = true
	_set_dash_fill_ratio(0.0)
	
func _on_dash_ready() -> void:
	dash_cooldown_active = false
	dash_cooldown_duration = 0.0
	dash_cooldown_time_left = 0.0
	_set_dash_fill_ratio(1.0)
	
func _on_checkpoint_reached() -> void:
	_show_message("Checkpoint reached")
	
func _on_player_unalived() -> void:
	_show_message("You died")
	
func _on_run_completed(final_value: String) -> void:
	level_complete_overlay.visible = true
	message_label.visible = false
	var level_complete_title = $LevelCompleteOverlay/CenterContainer/PanelContainer/VBoxContainer/TitleLabel
	
	if level and level.has_method("is_endless"):
		level_complete_title.text = "Game Over"
		time_label.text = "Distance: " + final_value
	else:
		level_complete_title.text = "Level Complete"
		time_label.text = "Time: " + final_value
	
func _on_pause_toggled(paused: bool) -> void:	
	ui_paused = paused
	
	if level_complete_overlay.visible:
		return
		
	pause_overlay.visible = paused
	
	if paused:
		message_label.visible = false
	
# ---------------------------------------------------------
# Finish overlay buttons
# ---------------------------------------------------------	

func _on_finish_restart_button_pressed() -> void:
	level.restart_level()
	
func _on_finish_back_button_pressed() -> void:
	level.return_to_menu()
	
# ---------------------------------------------------------
# Pause overlay buttons
# ---------------------------------------------------------	
	
func _on_pause_resume_button_pressed() -> void:
	level.resume_game()

func _on_pause_restart_button_pressed() -> void:
	level.restart_level()

func _on_pause_back_button_pressed() -> void:
	level.return_to_menu()
	
# ---------------------------------------------------------
# Helpers
# ---------------------------------------------------------
	
func _rebuild_boxes(container: HBoxContainer, active_count: int, total_count: int) -> void:
	_clear_container(container)
	
	for i in range(total_count):
		var is_active := i < active_count
		container.add_child(_make_box(is_active))
		
func _make_box(is_active: bool) -> ColorRect:
	var box := ColorRect.new()
	box.custom_minimum_size = Vector2(24, 24)
	
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_FILL
	
	if is_active:
		box.color = Color(0.65, 0.65, 0.65, 1.0)
	else:
		box.color = Color(0.22, 0.22, 0.22, 1.0)
		
	return box
	
func _clear_container(container: HBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()
		
func _show_message(text: String, duration: float = 1.6) -> void:
	message_label.text = text
	message_label.visible = true
	
	await get_tree().create_timer(duration).timeout
	
	if message_label.text == text:
		message_label.visible = false
		
func _set_dash_fill_ratio(ratio: float) -> void:
	ratio = clamp(ratio, 0.0, 1.0)
	dash_fill.size.x = dash_row.size.x * ratio
	
# ---------------------------------------------------------
# UI API
# ---------------------------------------------------------
	
func set_timer_text(text: String) -> void:
	timer_label.text = text
