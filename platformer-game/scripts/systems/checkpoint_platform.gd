extends Node3D

@onready var area: Area3D = $Area3D
@onready var respawn_point: Marker3D = $Marker3D
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var _activated := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("checkpoints")
	area.body_entered.connect(_on_area_3d_body_entered)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if _activated or not body.is_in_group("player"):
		return

	_activated = true
	body.request_checkpoint(respawn_point.global_position)
	audio_player.play()
