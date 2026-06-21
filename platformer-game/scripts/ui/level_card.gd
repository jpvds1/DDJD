class_name LevelCard
extends Button

@export var level_id: String = ""
@export var level_scene: String = ""   # "" => coming soon
@export var show_stars: bool = true

@onready var stars_label: Label = $StarsLabel

func _ready() -> void:
	disabled = level_scene == ""
	stars_label.visible = show_stars
	pressed.connect(_on_pressed)

func set_stars(stars: int) -> void:
	var text := ""
	for i in range(3):
		text += "★" if i < stars else "☆"
	stars_label.text = text

func set_distance_text(text: String) -> void:
	stars_label.visible = true
	stars_label.text = text

func _on_pressed() -> void:
	if level_scene == "":
		return
	get_viewport().gui_release_focus()
	Global.game_controller.change_3D_scene.call_deferred(level_scene)
