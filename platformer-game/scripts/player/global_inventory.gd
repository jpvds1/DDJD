extends Node

signal equipment_changed()

var unlocked_items: Array[GearItem] = []

var equipped_gear: Dictionary = {
	GearItem.Slot.HEAD: null,
	GearItem.Slot.CHEST: null,
	GearItem.Slot.BOOTS: null
}

func equip(item: GearItem) -> void:
	equipped_gear[item.slot] = item
	equipment_changed.emit()
	
func unequip(slot: GearItem.Slot) -> void:
	equipped_gear[slot] = null
	equipment_changed.emit()
