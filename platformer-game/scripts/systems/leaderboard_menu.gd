extends Control

@onready var title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var level_option: OptionButton = $CenterContainer/PanelContainer/VBoxContainer/LevelFilter/LevelOptionButton
@onready var my_score_label: Label = $CenterContainer/PanelContainer/VBoxContainer/MyScorePanel/MyScoreLabel
@onready var entries_container: VBoxContainer = $CenterContainer/PanelContainer/VBoxContainer/ScrollContainer/EntriesContainer
@onready var close_button: Button = $CenterContainer/PanelContainer/VBoxContainer/CloseButton

var current_level: String = ""

var levels: Array = []

func _ready() -> void:
	title_label.text = "Leaderboard"
	close_button.pressed.connect(queue_free)

	levels = _scan_levels()
	for level in levels:
		level_option.add_item(level.replace("_", " ").capitalize())

	level_option.item_selected.connect(_on_level_selected)

	if levels.size() > 0:
		load_scores(levels[0])

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free()

func _scan_levels() -> Array:
	var result = []
	var dir = DirAccess.open("res://scenes/levels")
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if file.ends_with(".tscn") and not file.begins_with("empty"):
				result.append(file.replace(".tscn", ""))
			file = dir.get_next()
		dir.list_dir_end()
	result.sort()
	return result

func load_scores(level_id: String) -> void:
	current_level = level_id

	for i in range(levels.size()):
		if levels[i] == level_id:
			level_option.select(i)
			break

	_clear_entries()
	_add_header()

	my_score_label.text = "Your best: loading..."

	var scores = await Supabase.get_scores(level_id, 10)

	if scores.is_empty():
		var empty = Label.new()
		empty.text = "No scores yet — be the first!"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		entries_container.add_child(empty)
	else:
		var my_user_id = ""
		if Supabase.is_logged_in():
			my_user_id = Supabase.current_user.get("id", "")

		for i in range(scores.size()):
			var s = scores[i]
			var is_me = s.get("user_id", "") == my_user_id
			_add_entry(
				"#%d" % (i + 1),
				s.get("username", "Unknown"),
				_format_ms(s.get("time_ms", 0)),
				i == 0,
				is_me
			)

	if Supabase.is_logged_in():
		var my = await Supabase.get_my_score(level_id)
		if my.is_empty():
			my_score_label.text = "You haven't completed this level yet"
		else:
			my_score_label.text = "Your best: %s" % _format_ms(my.get("time_ms", 0))
	else:
		my_score_label.text = "Sign in to track your score"

func _on_level_selected(index: int) -> void:
	load_scores(levels[index])

func _add_header() -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.add_child(_make_label("#", 50, true, false))
	row.add_child(_make_label("Player", 300, true, false))
	row.add_child(_make_label("Time", 140, true, false, HORIZONTAL_ALIGNMENT_RIGHT))
	entries_container.add_child(row)

	var sep = HSeparator.new()
	entries_container.add_child(sep)

func _add_entry(rank: String, username: String, time: String, is_first: bool, is_me: bool) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	if is_me:
		var bg = StyleBoxFlat.new()
		bg.bg_color = Color(1, 1, 0, 0.08)
		row.add_theme_stylebox_override("panel", bg)

	row.add_child(_make_label(rank, 50, is_first, is_me))
	row.add_child(_make_label(username, 300, is_first, is_me))
	row.add_child(_make_label(time, 140, is_first, is_me, HORIZONTAL_ALIGNMENT_RIGHT))
	entries_container.add_child(row)

func _make_label(text: String, min_width: int, gold: bool = false, highlight: bool = false, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label = Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(min_width, 0)
	label.horizontal_alignment = align

	if gold:
		label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	elif highlight:
		label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))

	return label

func _clear_entries() -> void:
	for child in entries_container.get_children():
		child.queue_free()

func _format_ms(ms: int) -> String:
	var minutes := ms / 60000
	var secs := (ms % 60000) / 1000
	var millis := ms % 1000
	return "%02d:%02d.%03d" % [minutes, secs, millis]
