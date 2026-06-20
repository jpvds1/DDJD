extends Area3D

@export var speed: float = 2.0
@export var amplitude: float = 0.2

var initial_y_position: float = 0.0
@onready var visual_block: Node3D = get_parent() as Node3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	body_entered.connect(_on_body_entered)
	if visual_block:
		initial_y_position = visual_block.position.y

func _process(_delta: float) -> void:
	if not visual_block:
		return

	var time_seconds: float = Time.get_ticks_msec() * 0.001
	visual_block.position.y = initial_y_position + sin(time_seconds * speed) * amplitude

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("request_unalive"):
		body.request_unalive()
