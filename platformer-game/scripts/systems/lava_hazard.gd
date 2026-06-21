extends Area3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("request_unalive"):
		body.request_unalive()
