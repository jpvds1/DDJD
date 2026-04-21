extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func _on_play_pressed() -> void:
	Global.game_controller.change_GUI_scene("uid://b3y48lsib427f")


func _on_settings_pressed() -> void:
	print("Settings")


func _on_quit_pressed() -> void:
	get_tree().quit()
