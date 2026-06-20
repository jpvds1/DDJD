extends Control

const _LEVEL_IDS := {
	"VBoxContainer/HBoxContainer/Level1": "tutorial",
	"VBoxContainer/HBoxContainer/Level2": "level_1",
	"VBoxContainer/HBoxContainer/Level3": "level_2",
}

func _ready() -> void:
	_populate_level_stars()

func _populate_level_stars() -> void:
	for node_path in _LEVEL_IDS:
		var btn := get_node_or_null(node_path) as Button
		if btn == null:
			continue
		var stars: int = GlobalInventory.get_stars_for_level(_LEVEL_IDS[node_path])
		_add_star_label_to_button(btn, stars)

func _add_star_label_to_button(btn: Button, stars: int) -> void:
	var lbl := Label.new()
	lbl.text = _make_star_text(stars)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	lbl.offset_top = -30.0
	lbl.offset_bottom = 0.0

func _make_star_text(stars: int) -> String:
	var text := ""
	for i in range(3):
		text += "★" if i < stars else "☆"
	return text


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE and event.pressed:
		_on_back_button_pressed()


func _on_back_button_pressed() -> void:
	Global.game_controller.change_GUI_scene("res://scenes/ui/main_menu.tscn")


func _on_level_1_pressed() -> void:
	# Tira o foco de qualquer elemento de UI (como o próprio botão)
	get_viewport().gui_release_focus()
	
	# call_deferred garante que a troca só ocorra após o clique terminar
	var path = "res://scenes/levels/tutorial.tscn"
	Global.game_controller.change_3D_scene.call_deferred(path)


func _on_level_2_pressed() -> void:
	# Tira o foco de qualquer elemento de UI (como o próprio botão)
	get_viewport().gui_release_focus()
	
	# call_deferred garante que a troca só ocorra após o clique terminar
	var path = "res://scenes/levels/level_1.tscn"
	Global.game_controller.change_3D_scene.call_deferred(path)


func _on_level_3_pressed() -> void:
	# Tira o foco de qualquer elemento de UI (como o próprio botão)
	get_viewport().gui_release_focus()
	
	# call_deferred garante que a troca só ocorra após o clique terminar
	var path = "res://scenes/levels/level_2.tscn"
	Global.game_controller.change_3D_scene.call_deferred(path)


func _on_level_4_pressed() -> void:
	pass # Replace with function body.


func _on_level_5_pressed() -> void:
	pass # Replace with function body.


func _on_level_6_pressed() -> void:
	pass # Replace with function body.
