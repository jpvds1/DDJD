extends Control


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
