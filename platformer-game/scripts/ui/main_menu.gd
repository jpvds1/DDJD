extends Control


@onready var leaderboard_button: Button = $CenterContainer/Column/VBoxContainer2/Leaderboard


func _ready() -> void:
	leaderboard_button.visible = not OS.has_feature("web")
	
func _on_play_pressed() -> void:
	Global.game_controller.change_GUI_scene("res://scenes/ui/levels_menu.tscn")

func _on_leaderboard_pressed() -> void:
	var lb = preload("res://scenes/ui/leaderboard_menu.tscn").instantiate()
	add_child(lb)

func _on_settings_pressed() -> void:
	Global.settings_return_scene = "res://scenes/ui/main_menu.tscn"
	Global.game_controller.change_GUI_scene("res://scenes/ui/settings_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
