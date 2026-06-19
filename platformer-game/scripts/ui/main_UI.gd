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

# Star display
@onready var star_3_icon: Label = $StarPanel/Star3Row/Star3Icon
@onready var star_3_time_label: Label = $StarPanel/Star3Row/Star3TimeLabel
@onready var star_2_icon: Label = $StarPanel/Star2Row/Star2Icon
@onready var star_2_time_label: Label = $StarPanel/Star2Row/Star2TimeLabel
@onready var star_1_icon: Label = $StarPanel/Star1Row/Star1Icon
@onready var star_1_time_label: Label = $StarPanel/Star1Row/Star1TimeLabel

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
# Star display state
# ---------------------------------------------------------

var _star_thresholds: Array = [0.0, 0.0, 0.0]
var _star_icon_nodes: Array = []

const _COLOR_STAR_LIT := Color(1.0, 0.85, 0.2, 1.0)
const _COLOR_STAR_DIM := Color(0.35, 0.35, 0.35, 1.0)

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
	
	_setup_star_display()
	
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
	
	if level != null and level.timer_running:
		_update_star_icons(level.run_time)
		
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
	
func _on_run_completed(final_time: String, _stars: int) -> void:
	_update_star_icons(level.run_time)
	level_complete_overlay.visible = true
	message_label.visible = false
	time_label.text = "Time: " + final_time
	
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
# Star display
# ---------------------------------------------------------

func _setup_star_display() -> void:
	_star_thresholds[0] = level.time_3_stars
	_star_thresholds[1] = level.time_2_stars
	_star_thresholds[2] = level.time_1_star
	_star_icon_nodes = [star_3_icon, star_2_icon, star_1_icon]
	
	var time_labels: Array = [star_3_time_label, star_2_time_label, star_1_time_label]
	for i in range(3):
		var t: float = _star_thresholds[i]
		time_labels[i].text = ("< " + _format_time(t)) if t > 0.0 else "—"
	
	_update_star_icons(0.0)

func _update_star_icons(current_time: float) -> void:
	for i in range(3):
		var threshold: float = _star_thresholds[i]
		var icon: Label = _star_icon_nodes[i]
		if threshold <= 0.0:
			icon.text = "☆"
			icon.add_theme_color_override("font_color", _COLOR_STAR_DIM)
		elif current_time <= threshold:
			icon.text = "★"
			icon.add_theme_color_override("font_color", _COLOR_STAR_LIT)
		else:
			icon.text = "☆"
			icon.add_theme_color_override("font_color", _COLOR_STAR_DIM)

func _format_time(seconds: float) -> String:
	var total_ms := int(round(seconds * 1000.0))
	var minutes := total_ms / 60000
	var secs := (total_ms % 60000) / 1000
	var ms := total_ms % 1000
	return "%02d:%02d.%03d" % [minutes, secs, ms]
		
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
