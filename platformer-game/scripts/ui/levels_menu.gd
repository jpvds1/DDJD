extends Control

@onready var loadout: Button = $Loadout

func _ready() -> void:
	for card in _level_cards():
		if card.level_id != "":
			card.set_stars(GlobalInventory.get_stars_for_level(card.level_id))
	if !Supabase.is_logged_in():
		loadout.visible = false

func _level_cards() -> Array[LevelCard]:
	var cards: Array[LevelCard] = []
	for row in $VBoxContainer.get_children():
		for child in row.get_children():
			if child is LevelCard:
				cards.append(child)
	return cards

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE and event.pressed:
		_on_back_button_pressed()

func _on_loadout_pressed() -> void:
	Global.game_controller.change_GUI_scene("res://scenes/ui/customization_menu.tscn")

func _on_level_2_pressed() -> void:
	get_viewport().gui_release_focus()
	var path = "res://scenes/levels/level_1.tscn"
	Global.game_controller.change_3D_scene.call_deferred(path)


func _on_level_3_pressed() -> void:
	get_viewport().gui_release_focus()
	var path = "res://scenes/levels/level_2.tscn"
	Global.game_controller.change_3D_scene.call_deferred(path)


func _on_level_4_pressed() -> void:
	pass


func _on_level_5_pressed() -> void:
	pass


func _on_level_6_pressed() -> void:
	get_viewport().gui_release_focus()
	var path = "res://scenes/levels/level_6.tscn"
	Global.game_controller.change_3D_scene.call_deferred(path)


func _on_back_button_pressed() -> void:
	Global.game_controller.change_GUI_scene("res://scenes/ui/main_menu.tscn")
