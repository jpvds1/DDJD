extends Control

@onready var level_label: Label = $CenterContainer/PanelContainer/VBoxContainer/LevelLabel
@onready var entries_container: VBoxContainer = $CenterContainer/PanelContainer/VBoxContainer/ScrollContainer/EntriesContainer
@onready var close_button: Button = $CenterContainer/PanelContainer/VBoxContainer/CloseButton

var level_id: String = ""

func _ready() -> void:
	close_button.pressed.connect(queue_free)

func load_scores(p_level_id: String) -> void:
	level_id = p_level_id
	level_label.text = "Level: " + level_id.replace("_", " ").capitalize()
	
	_clear_entries()
	_add_entry("#", "Player", "Time", true)
	
	var scores = await Supabase.get_scores(level_id, 10)
	
	if scores.is_empty():
		var empty = Label.new()
		empty.text = "No scores yet — be the first!"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		entries_container.add_child(empty)
		return
	
	for i in range(scores.size()):
		var s = scores[i]
		var rank = "#%d" % (i + 1)
		var username = s.get("username", "Unknown")
		var time_str = _format_ms(s.get("time_ms", 0))
		_add_entry(rank, username, time_str, i == 0)

# ---------------------------------------------------------
# Helpers
# ---------------------------------------------------------

func _add_entry(rank: String, username: String, time: String, is_first: bool = false) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	
	var rank_label = _make_label(rank, 60, is_first)
	var name_label = _make_label(username, 280, is_first)
	var time_label = _make_label(time, 120, is_first)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	row.add_child(rank_label)
	row.add_child(name_label)
	row.add_child(time_label)
	entries_container.add_child(row)

func _make_label(text: String, min_width: int, bold: bool = false) -> Label:
	var label = Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(min_width, 0)
	if bold:
		label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	return label

func _clear_entries() -> void:
	for child in entries_container.get_children():
		child.queue_free()

func _format_ms(ms: int) -> String:
	var minutes := ms / 60000
	var secs := (ms % 60000) / 1000
	var millis := ms % 1000
	return "%02d:%02d.%03d" % [minutes, secs, millis]
