extends Control

@onready var google_button: Button = $VBoxContainer2/Google
@onready var guest_button: Button = $VBoxContainer2/Guest
@onready var error_label: Label = $VBoxContainer2/Error
@onready var landing_screen: Control = $"."

func _ready() -> void:	
	error_label.visible = false
	google_button.pressed.connect(_on_google_pressed)
	guest_button.pressed.connect(_on_guest_pressed)
	
	_check_initial_auth.call_deferred()

func _check_initial_auth() -> void:
	if Supabase.is_logged_in():
		_go_to_main_menu()

func _on_google_pressed() -> void:
	_set_loading(true)
	await Supabase.sign_in_with_google()
	_set_loading(false)

	if Supabase.is_logged_in():
		_go_to_main_menu()
	else:
		_show_error("Google login failed. Please try again.")

func _on_guest_pressed() -> void:
	_go_to_main_menu()

func _go_to_main_menu() -> void:
	Global.game_controller.change_GUI_scene("res://scenes/ui/main_menu.tscn")

func _show_error(text: String) -> void:
	error_label.text = text
	error_label.visible = true

func _set_loading(loading: bool) -> void:
	google_button.disabled = loading
	guest_button.disabled = loading
