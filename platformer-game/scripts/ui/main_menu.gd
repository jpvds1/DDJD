extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func _on_play_pressed() -> void:
	Global.game_controller.change_GUI_scene("res://scenes/ui/levels_menu.tscn")


func _on_settings_pressed() -> void:
	print("Settings")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_tutorial_pressed() -> void:
	Global.game_controller.change_3D_scene("res://scenes/levels/tutorial.tscn")
