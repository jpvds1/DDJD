extends Node

signal equipment_changed()

var all_gear: Array[GearItem] = []
var unlocked_items: Array[GearItem] = []

var equipped_gear: Dictionary = {
	GearItem.Slot.HEAD: null,
	GearItem.Slot.CHEST: null,
	GearItem.Slot.BOOTS: null
}

func _ready() -> void:
	_load_all_gear("res://resources/gear_items/")
	for item in all_gear:
		unlock_item(item)

func _load_all_gear(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir():
				_load_all_gear(path + file_name + "/")
			elif file_name.ends_with(".tres"):
				var clean_path = path + file_name.replace(".remap", "")
				var item = load(clean_path)
				
				if item is GearItem:
					all_gear.append(item)
			
			file_name = dir.get_next()
	else:
		print("Error occurer when trying to load gear from path: ", path)

func unlock_item(item: GearItem) -> void:
	if not unlocked_items.has(item):
		unlocked_items.append(item)
		equipment_changed.emit()

func is_item_unlocked(item: GearItem) -> bool:
	return unlocked_items.has(item)

func equip(item: GearItem) -> void:
	equipped_gear[item.slot] = item
	equipment_changed.emit()
	
func unequip(slot: GearItem.Slot) -> void:
	equipped_gear[slot] = null
	equipment_changed.emit()
