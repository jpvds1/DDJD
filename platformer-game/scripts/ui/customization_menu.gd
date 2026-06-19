extends Control

# ---------------------------------------------------------
# Node references
# ---------------------------------------------------------

@onready var head_button: Button = $HBoxContainer/VBoxContainer/ActiveHeadGear
@onready var chest_button: Button = $HBoxContainer/VBoxContainer/ActiveChestGear
@onready var boots_button: Button = $HBoxContainer/VBoxContainer/ActiveBootsGear

@onready var grid_container: GridContainer = $HBoxContainer/GridContainer
@onready var stats_vbox: VBoxContainer = $HBoxContainer/StatsVBox
@onready var back_button: Button = $BackButton
@onready var stars_label: Label = $StarsLabel

# ---------------------------------------------------------
# State
# ---------------------------------------------------------

var _selected_slot: GearItem.Slot = GearItem.Slot.HEAD

var _slot_buttons: Dictionary

const SLOT_LABELS := {
	GearItem.Slot.HEAD: "Head",
	GearItem.Slot.CHEST: "Chest",
	GearItem.Slot.BOOTS: "Boots"
}

# Describe stats that gear can modify
const GEAR_STATS := [
	{ "field": "speed_bonus",            "label": "Speed",             "suffix": "",  "good_sign":  1 },
	{ "field": "acceleration_bonus",     "label": "Acceleration",      "suffix": "",  "good_sign":  1 },
	{ "field": "jump_velocity_bonus",    "label": "Jump Velocity",     "suffix": "",  "good_sign":  1 },
	{ "field": "extra_jumps",            "label": "Extra Jumps",       "suffix": "",  "good_sign":  1 },
	{ "field": "dash_cooldown_reduction","label": "Dash Cooldown",     "suffix": "s", "good_sign":  1 },
	{ "field": "extra_dashes",           "label": "Extra Dashes",      "suffix": "",  "good_sign":  1 },
]

# Colors
const COLOR_SELECTED   := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_UNSELECTED := Color(0.6, 0.6, 0.6, 1.0)
const COLOR_EQUIPPED   := Color(1.0, 0.85, 0.2, 1.0)
const COLOR_LOCKED     := Color(0.45, 0.45, 0.45, 1.0)
const COLOR_BUYABLE    := Color(0.4,  0.85, 1.0,  1.0)
const COLOR_BONUS_POS  := Color(0.35, 1.0,  0.45, 1.0)
const COLOR_BONUS_NEG  := Color(1.0,  0.38, 0.38, 1.0)
const COLOR_NO_BONUS   := Color(0.7,  0.7,  0.7,  1.0)

# Shared size for every gear grid entry (equip/unequip/buy/locked) so they all line up
const GEAR_ENTRY_SIZE := Vector2(360, 64)

# ---------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_slot_buttons = {
		GearItem.Slot.HEAD: head_button,
		GearItem.Slot.CHEST: chest_button,
		GearItem.Slot.BOOTS: boots_button
	}
	
	head_button.pressed.connect(_on_slot_button_pressed.bind(GearItem.Slot.HEAD))
	chest_button.pressed.connect(_on_slot_button_pressed.bind(GearItem.Slot.CHEST))
	boots_button.pressed.connect(_on_slot_button_pressed.bind(GearItem.Slot.BOOTS))
	
	GlobalInventory.equipment_changed.connect(_on_inventory_changed)
	GlobalInventory.unlock_changed.connect(_on_inventory_changed)
	GlobalInventory.stars_changed.connect(_on_stars_changed)
	
	_update_stars_label(GlobalInventory.total_stars)
	_on_slot_button_pressed(GearItem.Slot.HEAD)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE and event.pressed:
		_on_back_button_pressed()

# ---------------------------------------------------------
# Slot selection
# ---------------------------------------------------------

func _on_slot_button_pressed(slot: GearItem.Slot) -> void:
	_selected_slot = slot
	_refresh_slot_buttons()
	_refresh_grid()
	_refresh_stats_panel()

func _refresh_slot_buttons() -> void:
	for slot: GearItem.Slot in _slot_buttons:
		var btn: Button = _slot_buttons[slot]
		var item: GearItem = GlobalInventory.equipped_gear[slot]
		var item_label: String = item.item_name if item != null else "Empty"
		
		btn.text = "%s\n%s" % [SLOT_LABELS[slot], item_label]
		btn.modulate = COLOR_SELECTED if slot == _selected_slot else COLOR_UNSELECTED

# ---------------------------------------------------------
# Grid
# ---------------------------------------------------------

func _refresh_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()
		
	var slot_items: Array[GearItem] = []
	for item: GearItem in GlobalInventory.all_gear:
		if item.slot == _selected_slot:
			slot_items.append(item)
			
	if slot_items.is_empty():
		var placeholder := Label.new()
		placeholder.text = "No items unlocked for this slot"
		placeholder.modulate = COLOR_NO_BONUS
		grid_container.add_child(placeholder)
		return
	
	if GlobalInventory.equipped_gear[_selected_slot] != null:
		var unequip_btn := Button.new()
		unequip_btn.custom_minimum_size = GEAR_ENTRY_SIZE
		unequip_btn.text = "Unequip"
		unequip_btn.pressed.connect(_on_unequip_pressed)
		grid_container.add_child(unequip_btn)
		
	for item: GearItem in slot_items:
		_add_gear_entry(item)

# Builds one gear entry. Same button, same size, for every state - only the
# status line, color, and whether it's clickable change.
func _add_gear_entry(item: GearItem) -> void:
	var is_unlocked := GlobalInventory.is_item_unlocked(item)
	var is_equipped = item == GlobalInventory.equipped_gear[_selected_slot]
	
	var status_line: String
	var color: Color
	var can_interact: bool
	
	if is_unlocked:
		status_line = "Equipped" if is_equipped else "Tap to equip"
		color = COLOR_EQUIPPED if is_equipped else COLOR_SELECTED
		can_interact = not is_equipped
	elif item.unlock_type == GearItem.UnlockType.PURCHASE:
		var can_buy := GlobalInventory.can_purchase(item)
		status_line = "★  %d stars" % item.star_cost
		color = COLOR_BUYABLE if can_buy else COLOR_LOCKED
		can_interact = can_buy
	else:
		var desc := item.unlock_description
		if desc == "":
			match item.unlock_type:
				GearItem.UnlockType.LEVEL_COMPLETION:
					desc = "Complete a level to unlock"
				GearItem.UnlockType.ACHIEVEMENT:
					desc = "Unlock via achievement"
		status_line = "🔒 " + desc
		color = COLOR_LOCKED
		can_interact = false
		
	var btn := Button.new()
	btn.custom_minimum_size = GEAR_ENTRY_SIZE
	btn.clip_text = true
	btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	btn.text = "%s\n%s" % [item.item_name, status_line]
	btn.modulate = color
	btn.disabled = not can_interact
	
	if is_unlocked:
		btn.pressed.connect(_on_gear_item_pressed.bind(item))
	elif item.unlock_type == GearItem.UnlockType.PURCHASE:
		btn.pressed.connect(_on_purchase_pressed.bind(item))
		
	grid_container.add_child(btn)
 
# ---------------------------------------------------------
# Stats
# ---------------------------------------------------------

func _refresh_stats_panel() -> void:
	# Remove all except header
	var children := stats_vbox.get_children()
	for i in range(1, children.size()):
		children[i].queue_free()

	var totals: Dictionary = {}
	for entry in GEAR_STATS:
		totals[entry["field"]] = 0.0
		
	for slot: GearItem.Slot in GlobalInventory.equipped_gear:
		var item: GearItem = GlobalInventory.equipped_gear[slot]
		if item == null:
			continue
		for entry in GEAR_STATS:
			var field: String = entry["field"]
			totals[field] += float(item.get(field))
			
	var any_bonus := false
	for entry in GEAR_STATS:
		var field: String = entry["field"]
		var bonus: float = totals[field]
		var good_sign: int = entry["good_sign"]
		
		if bonus == 0.0:
			continue
		any_bonus = true
		
		var value_str: String
		if float(int(bonus)) == bonus:
			value_str = "%+d%s" % [int(bonus), entry["suffix"]]
		else:
			value_str = "%+.2f%s" % [bonus, entry["suffix"]]
			
		var display_text : String
		if field == "dash_cooldown_reduction":
			var sign_str := "-" if bonus > 0.0 else "+"
			var abs_str := "%.2f" % absf(bonus) if float(int(bonus)) != bonus else "%d" % int(absf(bonus))
			display_text = "Dash Cooldown: %s%s%s" % [sign_str, abs_str, entry["suffix"]]
		else:
			display_text = "%s: %s" % [entry["label"], value_str]
			
		var lbl := Label.new()
		lbl.text = display_text
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var is_beneficial := (bonus * good_sign) > 0.0
		lbl.modulate = COLOR_BONUS_POS if is_beneficial else COLOR_BONUS_NEG
		
		stats_vbox.add_child(lbl)
		
	if not any_bonus:
		var lbl := Label.new()
		lbl.text = "No active bonuses"
		lbl.modulate = COLOR_NO_BONUS
		stats_vbox.add_child(lbl)
		
# ---------------------------------------------------------
# Stars
# ---------------------------------------------------------
		
func _update_stars_label(new_total: int) -> void:
	if is_instance_valid(stars_label):
		stars_label.text = "★  %d Stars" % new_total
		
# ---------------------------------------------------------
# Callbacks
# ---------------------------------------------------------

func _on_gear_item_pressed(item: GearItem) -> void:
	GlobalInventory.equip(item)

func _on_unequip_pressed() -> void:
	GlobalInventory.unequip(_selected_slot)

func _on_purchase_pressed(item: GearItem) -> void:
	if GlobalInventory.purchase_item(item):
		GlobalInventory.equip(item)

func _on_inventory_changed() -> void:
	_refresh_slot_buttons()
	_refresh_grid()
	_refresh_stats_panel()
	
func _on_stars_changed(new_total: int) -> void:
	_update_stars_label(new_total)
	_refresh_grid()	
	
func _on_back_button_pressed() -> void:
	Global.game_controller.change_GUI_scene("res://scenes/ui/main_menu.tscn")
