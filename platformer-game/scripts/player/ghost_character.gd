extends Node3D

var replay_data: Array = []
var current_frame := 0
var is_playing := false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $Visuals/AnimationTree
@onready var visuals: Node3D = $Visuals
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D

# ---------------------------------------------------------
# Methods
# ---------------------------------------------------------

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_apply_ghost_material()


func _apply_ghost_material() -> void:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.7, 0.85, 1.0, 0.5)
	mat.roughness = 0.5
	_apply_material_recursive(self, mat)


func _apply_material_recursive(node: Node, mat: StandardMaterial3D) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = mat
	for child in node.get_children():
		_apply_material_recursive(child, mat)


func start_replay(data: Array) -> void:
	if data.is_empty():
		return
	replay_data = data
	current_frame = 0
	is_playing = true
	visible = true


func _physics_process(_delta: float) -> void:
	if not is_playing or replay_data.is_empty():
		return
		
	if current_frame >= replay_data.size():
		is_playing = false
		return
		
	var snapshot = replay_data[current_frame]
	
	global_position = snapshot["p"]
	global_rotation.y = snapshot["r"]
	
	var anim_name = snapshot["a"]
	if anim_name != "" and animation_player:
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name)

	if animation_tree:
		animation_tree.set("parameters/Fall/blend_amount", snapshot.get("fb", 1.0))
		animation_tree.set("parameters/Movement/blend_position", snapshot.get("mb", Vector2.ZERO))

	if visuals:
		visuals.rotation.z = snapshot.get("vz", 0.0)

	current_frame += 1
