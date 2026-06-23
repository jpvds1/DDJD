class_name GameController extends Node

@export var world_3d : Node3D
@export var world_2d : Node2D
@export var gui : Control


var current_3d_scene
var current_2d_scene
var current_gui_scene

func _ready() -> void:
	Global.game_controller = self
	Global.game_controller.change_GUI_scene("res://scenes/ui/main_menu.tscn")

func change_GUI_scene(scene_path: String, delete: bool = true, keep_running: bool = false, delete_previous: bool = true) -> void:
	if current_gui_scene != null:
		if delete:
			current_gui_scene.queue_free()
		elif keep_running:
			current_gui_scene.visible = false
		else:
			if current_gui_scene.get_parent():
				current_gui_scene.get_parent().remove_child(current_gui_scene)

	if delete_previous:
		if current_2d_scene != null:
			current_2d_scene.queue_free()
			current_2d_scene = null
		if current_3d_scene != null:
			current_3d_scene.queue_free()
			current_3d_scene = null

	var new_scene_res = load(scene_path)
	if new_scene_res:
		var new_scene = new_scene_res.instantiate()
		gui.add_child(new_scene)
		current_gui_scene = new_scene

func change_2D_scene(scene_path: String, delete: bool = true, keep_running: bool = false, delete_previous: bool = true) -> void:
	if delete_previous:
		if current_gui_scene != null:
			current_gui_scene.queue_free()
			current_gui_scene = null
		if current_3d_scene != null:
			current_3d_scene.queue_free()
			current_3d_scene = null

	if current_2d_scene != null:
		if delete:
			current_2d_scene.queue_free()
		elif keep_running:
			current_2d_scene.visible = false
		else:
			if current_2d_scene.get_parent():
				current_2d_scene.get_parent().remove_child(current_2d_scene)

	var new_scene_res = load(scene_path)
	if new_scene_res:
		var new_scene = new_scene_res.instantiate()
		world_2d.add_child(new_scene)
		current_2d_scene = new_scene

func change_3D_scene(scene_path: String, delete: bool = true, keep_running: bool = false, delete_previous: bool = true) -> void:
	if delete_previous:
		if current_gui_scene != null:
			current_gui_scene.queue_free()
			current_gui_scene = null
		if current_2d_scene != null:
			current_2d_scene.queue_free()
			current_2d_scene = null

	if current_3d_scene != null:
		if delete:
			current_3d_scene.queue_free()
		elif keep_running:
			current_3d_scene.visible = false
		else:
			if current_3d_scene.get_parent():
				current_3d_scene.get_parent().remove_child(current_3d_scene)

	var new_scene_res = load(scene_path)
	if new_scene_res:
		var new_scene = new_scene_res.instantiate()
		world_3d.add_child(new_scene)
		current_3d_scene = new_scene
