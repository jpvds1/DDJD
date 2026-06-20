extends Resource
class_name GearSet

@export var set_name: String = ""
@export var set_description: String = ""

@export_group("Set Bonus")
@export var speed_bonus: float = 0.0
@export var acceleration_bonus: float = 0.0
@export var jump_velocity_bonus: float = 0.0
@export var extra_jumps: int = 0
@export var dash_cooldown_reduction: float = 0.0
@export var extra_dashes: int = 0
