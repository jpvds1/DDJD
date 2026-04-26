extends Control

func _ready() -> void:
	Supabase.auth_changed.connect(_on_auth_changed)
	_on_auth_changed(Supabase.current_user)

func _on_auth_changed(user) -> void:
	if has_node("VBoxContainer2/Login"):
		$VBoxContainer2/Login.text = "Logout" if user else "Login / Register"

func _on_play_pressed() -> void:
	Global.game_controller.change_GUI_scene("res://scenes/ui/levels_menu.tscn")

func _on_tutorial_pressed() -> void:
	Global.game_controller.change_3D_scene("res://scenes/levels/tutorial.tscn")

func _on_login_pressed() -> void:
	if Supabase.is_logged_in():
		await Supabase.sign_out()
	else:
		var auth = preload("res://scenes/ui/auth_menu.tscn").instantiate()
		add_child(auth)

func _on_leaderboard_pressed() -> void:
	var lb = preload("res://scenes/ui/leaderboard_menu.tscn").instantiate()
	add_child(lb)
	lb.load_scores("tutorial")

func _on_settings_pressed() -> void:
	print("Settings")

func _on_quit_pressed() -> void:
	get_tree().quit()
