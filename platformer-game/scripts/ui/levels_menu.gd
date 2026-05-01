extends Control

# -------------------------------------------------------
# Dynamic Level Loader
# -------------------------------------------------------

const LEVELS_PATH := "res://scenes/levels/"
const LEVEL_PATTERN := "level_"

var _levels_data: Array[Dictionary] = []

# -------------------------------------------------------
# Lifecycle
# -------------------------------------------------------

func _ready() -> void:
	_scan_and_populate_levels()


# -------------------------------------------------------
# Level Scanning
# -------------------------------------------------------

func _scan_and_populate_levels() -> void:
	"""Scan levels folder, parse level files, and generate buttons dynamically."""
	_levels_data.clear()
	
	# Scan directory for level files
	var dir_access = DirAccess.open(LEVELS_PATH)
	if dir_access == null:
		push_error("Failed to open levels directory: %s" % LEVELS_PATH)
		return
	
	dir_access.list_dir_begin()
	var file_name = dir_access.get_next()
	
	while file_name != "":
		# Filter: only .tscn files matching level_X pattern
		if file_name.ends_with(".tscn") and file_name.begins_with(LEVEL_PATTERN):
			var level_num = _extract_level_number(file_name)
			if level_num > 0:
				_levels_data.append({
					"number": level_num,
					"file_name": file_name,
					"path": LEVELS_PATH + file_name
				})
		
		file_name = dir_access.get_next()
	
	# Sort numerically by level number
	_levels_data.sort_custom(func(a, b): return a["number"] < b["number"])
	
	# Debug: Print detected levels
	print("Niveles detectados: ", _levels_data.size())
	for level in _levels_data:
		print("  Nivel %d: %s" % [level["number"], level["path"]])
	
	# Generate buttons
	_create_level_buttons()


func _extract_level_number(file_name: String) -> int:
	"""Extract numeric suffix from level_X.tscn format."""
	# Remove extension
	var base_name = file_name.trim_suffix(".tscn")
	
	# Remove "level_" prefix
	if base_name.begins_with(LEVEL_PATTERN):
		var num_str = base_name.substr(LEVEL_PATTERN.length())
		
		# Try to parse as integer
		if num_str.is_valid_int():
			return int(num_str)
	
	return -1


func _create_level_buttons() -> void:
	"""Dynamically create buttons for each discovered level."""
	if _levels_data.is_empty():
		push_warning("No level files found in %s" % LEVELS_PATH)
		return
	
	# Get the container where buttons should be placed
	var button_container = get_node_or_null("VBoxContainer/HBoxContainer")
	if button_container == null:
		push_error("Button container not found: VBoxContainer/HBoxContainer")
		return
	
	# Clear existing buttons (optional, for safety)
	for child in button_container.get_children():
		child.queue_free()
	
	# Create button for each level
	for level_data in _levels_data:
		var button = Button.new()
		button.text = str(level_data["number"])
		button.custom_minimum_size = Vector2(124, 124)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		# Store the level path as metadata for later retrieval
		button.set_meta("level_path", level_data["path"])
		
		# Connect the signal
		button.pressed.connect(_on_level_selected.bindv([level_data["path"]]))
		
		# Add to container
		button_container.add_child(button)


# -------------------------------------------------------
# Level Selection
# -------------------------------------------------------

func _on_level_selected(level_path: String) -> void:
	"""Load the selected level."""
	print("Cargando nivel: ", level_path)
	get_viewport().gui_release_focus()
	Global.game_controller.change_3D_scene.call_deferred(level_path)

