extends CanvasLayer

@export var player_path: NodePath

@onready var lives_container: HBoxContainer = $RootMargin/MainVBox/LivesContainer
@onready var jumps_container: HBoxContainer = $RootMargin/MainVBox/JumpsContainer

@onready var dash_row: Control = $RootMargin/MainVBox/DashRow
@onready var dash_background: ColorRect = $RootMargin/MainVBox/DashRow/DashBackground
@onready var dash_fill: ColorRect = $RootMargin/MainVBox/DashRow/DashFill

@onready var message_label: Label = $MessageTop/MessageCenter/MessageLabel

var dash_tween: Tween = null

var player: Node = null

func _ready() -> void:
	player = get_node_or_null(player_path)
	
	if player == null:
		push_error("UI: player_path is not assigned or player was not found.")
		return
		
	player.lives_changed.connect(_on_lives_changed)
	player.extra_jumps_changed.connect(_on_extra_jumps_changed)
	
	player.dash_cooldown_started.connect(_on_dash_cooldown_started)
	player.dash_ready.connect(_on_dash_ready)
	
	player.checkpoint_reached.connect(_on_checkpoint_reached)
	player.player_unalived.connect(_on_player_unalived)
	player.end_reached.connect(_on_end_reached)
	
	message_label.visible = false
	
	player.emit_initial_ui_state()
	
func _on_lives_changed(current_lives: int, max_lives: int) -> void:
	_rebuild_boxes(lives_container, current_lives, max_lives)
	
func _on_extra_jumps_changed(current_extra_jumps: int, max_extra_jumps: int) -> void:
	_rebuild_boxes(jumps_container, current_extra_jumps, max_extra_jumps)
	
func _on_dash_cooldown_started(duration: float) -> void:
	_set_dash_fill_ratio(0.0)
	
	if dash_tween != null and dash_tween.is_valid():
		dash_tween.kill()
		
	dash_tween = create_tween()
	dash_tween.tween_method(_set_dash_fill_ratio, 0.0, 1.0, duration)
	
func _on_dash_ready() -> void:
	if dash_tween != null and dash_tween.is_valid():
		dash_tween.kill()
		
	_set_dash_fill_ratio(1.0)
	
func _on_checkpoint_reached() -> void:
	_show_message("Checkpoint reached")
	
func _on_player_unalived() -> void:
	_show_message("You died")
	
func _on_end_reached() -> void:
	_show_message("Level complete")
	
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
