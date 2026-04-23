extends Control


func _ready() -> void:
	pass # Replace with function body.


func _on_level_1_pressed() -> void:
	# Tira o foco de qualquer elemento de UI (como o próprio botão)
	get_viewport().gui_release_focus()
	
	# call_deferred garante que a troca só ocorra após o clique terminar
	var path = "res://scenes/levels/level_1.tscn"
	Global.game_controller.change_3D_scene.call_deferred(path)


func _on_level_2_pressed() -> void:
	pass # Replace with function body.


func _on_level_3_pressed() -> void:
	pass # Replace with function body.


func _on_level_4_pressed() -> void:
	pass # Replace with function body.


func _on_level_5_pressed() -> void:
	pass # Replace with function body.


func _on_level_6_pressed() -> void:
	pass # Replace with function body.
