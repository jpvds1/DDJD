extends Control

@onready var title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var error_label: Label = $CenterContainer/PanelContainer/VBoxContainer/ErrorLabel
@onready var google_button: Button = $CenterContainer/PanelContainer/VBoxContainer/GoogleButton
@onready var guest_button: Button = $CenterContainer/PanelContainer/VBoxContainer/GuestButton

signal auth_completed

func _ready() -> void:
	title_label.text = "Sign in to save your scores"
	error_label.visible = false
	error_label.modulate = Color.RED
	google_button.text = "Sign in with Google"
	guest_button.text = "Continue as Guest"
	google_button.pressed.connect(_on_google_pressed)
	guest_button.pressed.connect(_on_guest_pressed)

func _on_google_pressed() -> void:
	_set_loading(true)
	await Supabase.sign_in_with_google()
	_set_loading(false)

	if Supabase.is_logged_in():
		auth_completed.emit()
		queue_free()
	else:
		_show_error("Google login failed")

func _on_guest_pressed() -> void:
	queue_free()

func _show_error(text: String) -> void:
	error_label.text = text
	error_label.visible = text != ""

func _set_loading(loading: bool) -> void:
	google_button.disabled = loading
	guest_button.disabled = loading
