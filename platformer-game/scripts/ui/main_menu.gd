extends Control

@onready var customization: Button = $VBoxContainer2/Customization

func _ready() -> void:
	if !Supabase.is_logged_in():
		customization.visible = false

func _on_play_pressed() -> void:
	Global.game_controller.change_GUI_scene("res://scenes/ui/levels_menu.tscn")

func _on_tutorial_pressed() -> void:
	Global.game_controller.change_3D_scene.call_deferred("res://scenes/levels/tutorial.tscn")
	
func _on_customization_pressed() -> void:
	Global.game_controller.change_GUI_scene("res://scenes/ui/customization_menu.tscn")

func _on_leaderboard_pressed() -> void:
	var lb = preload("res://scenes/ui/leaderboard_menu.tscn").instantiate()
	add_child(lb)

func _on_settings_pressed() -> void:
	Global.game_controller.change_GUI_scene("res://scenes/ui/settings_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
