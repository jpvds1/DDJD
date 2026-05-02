extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pressed() -> void:
	if Supabase.is_logged_in():
		await Supabase.sign_out()
		Global.game_controller.change_GUI_scene("res://scenes/ui/landing_screen.tscn")
