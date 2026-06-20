extends Resource
class_name GearItem

enum Slot { HEAD, CHEST, BOOTS }
enum UnlockType { FREE, LEVEL_COMPLETION, PURCHASE, ACHIEVEMENT }

@export var item_name: String = "New Gear"
@export var slot: Slot
# @export var texture: Texture2D

@export_group("Unlock")
@export var unlock_type: UnlockType = UnlockType.LEVEL_COMPLETION
@export var star_cost: int = 0
@export var achievement_id: String = ""
@export var unlock_description: String = ""

@export var set_name: String = ""

@export_group("Modifiers")
@export var speed_bonus: float = 0.0
@export var acceleration_bonus: float = 0.0
@export var jump_velocity_bonus: float = 0.0
@export var extra_jumps: int = 0
@export var dash_cooldown_reduction: float = 0.0
@export var extra_dashes: int = 0
