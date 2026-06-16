extends Node

# ---------------------------------------------------------
# Signals
# ---------------------------------------------------------		

signal equipment_changed()
signal unlock_changed()
signal stars_changed(new_total: int)

# ---------------------------------------------------------
# Constants
# ---------------------------------------------------------		

const SAVE_PATH := "user://player_progress.json"

# ---------------------------------------------------------
# State
# ---------------------------------------------------------		

var all_gear: Array[GearItem] = []
var unlocked_items: Array[GearItem] = []

var equipped_gear: Dictionary = {
	GearItem.Slot.HEAD: null,
	GearItem.Slot.CHEST: null,
	GearItem.Slot.BOOTS: null
}

var total_stars: int = 0
var stars_per_level: Dictionary = {}
var completed_levels: Array[String] = []
var completed_achievements: Array[String] = []

# ---------------------------------------------------------
# Setup
# ---------------------------------------------------------		

func _ready() -> void:
	_load_all_gear("res://resources/gear_items/")
	_load_progress()
	
	for item in all_gear:
		if item.unlock_type == GearItem.UnlockType.FREE:
			_unlock_silent(item)
			
# ---------------------------------------------------------
# Gear Discovery
# ---------------------------------------------------------		

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

# ---------------------------------------------------------
# Persistence
# ---------------------------------------------------------		

func _save_progress() -> void:
	var unlocked_paths: Array = []
	for item: GearItem in unlocked_items:
		unlocked_paths.append(item.resource_path)
		
	var equipped_data: Dictionary = {}
	for slot: GearItem.Slot in equipped_gear:
		var item: GearItem = equipped_gear[slot]
		equipped_data[str(int(slot))] = item.resource_path if item != null else ""
		
	var data := {
		"unlocked_gear": unlocked_paths,
		"equipped_gear": equipped_data,
		"total_stars": total_stars,
		"stars_per_level": stars_per_level,
		"completed_levels": completed_levels,
		"completed_achievements": completed_achievements
	}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GlobalInventory: cannot write save file at " + SAVE_PATH)
		return
	
	file.store_string(JSON.stringify(data))
	file.close()
	
	# TODO
	# Supabase
	
func _load_progress() -> void:
	# TODO
	# Supabase
	
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
		
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	
	if not data is Dictionary:
		push_warning("GlobalInventory: save file error, starting fresh")
		return
		
	_apply_progress_data(data)
	
func _apply_progress_data(data: Dictionary) -> void:
	total_stars = int(data.get("total_stars", 0))
	stars_per_level = data.get("stars_per_level", {})
	
	completed_levels.clear()
	for v in data.get("completed_levels", []):
		completed_levels.append(str(v))
		
	completed_achievements.clear()
	for v in data.get("completed_achievements", []):
		completed_achievements.append(str(v))
		
	var unlocked_paths: Array = data.get("unlocked_gear", [])
	unlocked_items.clear()
	for item: GearItem in all_gear:
		if item.resource_path in unlocked_paths:
			unlocked_items.append(item)
			
	var equipped_data: Dictionary = data.get("equipped_gear", {})
	for slot: GearItem.Slot in equipped_gear:
		var key := str(int(slot))
		var path: String = equipped_data.get(key, "")
		equipped_gear[slot] = null
		if path != "":
			for item: GearItem in all_gear:
				if item.resource_path == path:
					equipped_gear[slot] = item
					break
					
	equipment_changed.emit()
	unlock_changed.emit()
	stars_changed.emit(total_stars)

# ---------------------------------------------------------
# Stars
# ---------------------------------------------------------		

func award_stars(level_id: String, stars: int) -> void:
	if stars <= 0:
		return
	var previous_best: int = stars_per_level.get(level_id, 0)
	if stars > previous_best:
		total_stars += stars - previous_best
		stars_per_level[level_id] = stars
		stars_changed.emit(total_stars)
		_save_progress()
		
func get_stars_for_level(level_id: String) -> int:
	return stars_per_level.get(level_id, 0)
	
# ---------------------------------------------------------
# Level Completion
# ---------------------------------------------------------	

func complete_level(level_id: String, gear_reward: GearItem) -> void:
	if level_id in completed_levels:
		return
		
	completed_levels.append(level_id)
	
	if gear_reward != null and gear_reward.unlock_type == GearItem.UnlockType.LEVEL_COMPLETION:
		unlock_item(gear_reward)
	else:
		_save_progress()
		
func is_level_completed(level_id: String) -> bool:
	return level_id in completed_levels
	
# ---------------------------------------------------------
# Achievements
# ---------------------------------------------------------		

func complete_achievement(achievement_id: String) -> void:
	if achievement_id in completed_achievements:
		return
		
	completed_achievements.append(achievement_id)
	
	var unlocked_something := false
	for item: GearItem in all_gear:
		if item.unlock_type == GearItem.UnlockType.ACHIEVEMENT and item.achievement_id == achievement_id:
			_unlock_silent(item)
			unlocked_something = true
			
	if unlocked_something:
		unlock_changed.emit()
		equipment_changed.emit()
		
	_save_progress()
	
func is_achievement_completed(achievement_id: String) -> bool:
	return achievement_id in completed_achievements
	
# ---------------------------------------------------------
# Store
# ---------------------------------------------------------		
	
func can_purchase(item: GearItem) -> bool:
	return item.unlock_type == GearItem.UnlockType.PURCHASE and not is_item_unlocked(item) and total_stars >= item.star_cost
	
func purchase_item(item: GearItem) -> bool:
	if not can_purchase(item):
		return false
	total_stars -= item.star_cost
	stars_changed.emit(total_stars)
	unlock_item(item)
	return true
	
# ---------------------------------------------------------
# API
# ---------------------------------------------------------		

func unlock_item(item: GearItem) -> void:
	if unlocked_items.has(item):
		return
	_unlock_silent(item)
	unlock_changed.emit()
	equipment_changed.emit()
	_save_progress()
	
func _unlock_silent(item: GearItem) -> void:
	if not unlocked_items.has(item):
		unlocked_items.append(item)

func is_item_unlocked(item: GearItem) -> bool:
	return unlocked_items.has(item)

func equip(item: GearItem) -> void:
	if not is_item_unlocked(item):
		return
	equipped_gear[item.slot] = item
	equipment_changed.emit()
	_save_progress()
	
func unequip(slot: GearItem.Slot) -> void:
	equipped_gear[slot] = null
	equipment_changed.emit()
	_save_progress()
