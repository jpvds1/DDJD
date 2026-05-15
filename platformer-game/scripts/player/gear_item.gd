extends Resource
class_name GearItem

enum Slot { HEAD, CHEST, BOOTS }

@export var item_name: String = "New Gear"
@export var slot: Slot
# @export var texture: Texture2D

@export_group("Modifiers")
@export var speed_bonus: float = 0.0
@export var acceleration_bonus: float = 0.0
@export var jump_velocity_bonus: float = 0.0
@export var extra_jumps: int = 0
@export var dash_cooldown_reduction: float = 0.0
@export var extra_dashes: int = 0
