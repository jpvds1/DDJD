extends Node3D

var replay_data: Array = []
var current_frame := 0
var is_playing := false

@onready var animation_player: AnimationPlayer = $Node3D/Dash/AnimationPlayer
@onready var animation_tree: AnimationTree = $Node3D/Visuals/Body/AnimationTree
@onready var visuals: Node3D = $Node3D/Visuals

func _ready() -> void:
	_setup_wings()
	_apply_ghost_material()

func _setup_wings() -> void:
	var skeleton := $Node3D/Visuals/Body/Armature/Skeleton3D as Skeleton3D
	if skeleton == null:
		return
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = "mixamorig_Head"
	skeleton.add_child(attachment)
	attachment.bone_idx = skeleton.find_bone("mixamorig_Head")
	var wings: Node3D = (load("res://assets/models/cosmetics/wings.glb") as PackedScene).instantiate()
	wings.scale = Vector3(100, 100, 100)
	wings.position = Vector3(0.07690239, 38.89086, -3.3907375)
	attachment.add_child(wings)

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
		visuals.rotation.z = -snapshot.get("vz", 0.0)

	current_frame += 1
