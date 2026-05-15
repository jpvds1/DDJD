extends Control

@onready var sign_out: Button = $VBoxContainer2/SignOut

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !Supabase.is_logged_in():
		sign_out.text = "landing_screen"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_sign_out_pressed() -> void:
	if Supabase.is_logged_in():
		await Supabase.sign_out()
	
	Global.game_controller.change_GUI_scene("res://scenes/ui/landing_screen.tscn")
