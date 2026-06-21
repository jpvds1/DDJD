extends Node

# ---------------------------------------------------------
# ID Constants 
# ---------------------------------------------------------

const AIR_TIME_ID := "air_time_5s"
const NO_EXTRA_JUMPS_ID := "no_extra_jumps"
const NO_DEATHS_ID := "no_deaths"
const ENDLESS_500M_ID := "endless_500m"

const AIR_TIME_THRESHOLD := 5.0

# ---------------------------------------------------------
# Runtime State
# ---------------------------------------------------------

var player: CharacterBody3D = null
var current_air_time := 0.0
var level_done := false

# ---------------------------------------------------------
# Per-frame Traicking
# ---------------------------------------------------------

func _physics_process(delta: float) -> void:
	if level_done:
		return
	if not is_instance_valid(player):
		var candidate = get_tree().get_first_node_in_group("player")
		if candidate is CharacterBody3D:
			player = candidate as CharacterBody3D
		current_air_time = 0.0
		return
	
	if player.is_on_floor():
		current_air_time = 0.0
	else:
		current_air_time += delta
		if current_air_time >= AIR_TIME_THRESHOLD:
			GlobalInventory.complete_achievement(AIR_TIME_ID)

# ---------------------------------------------------------
# Helpers
# ---------------------------------------------------------

func check_level_completion_achievements(extra_jumps_used: bool, died_this_run: bool) -> void:
	level_done = true
	current_air_time = 0.0
	if not extra_jumps_used:
		GlobalInventory.complete_achievement(NO_EXTRA_JUMPS_ID)
	if not died_this_run:
		GlobalInventory.complete_achievement(NO_DEATHS_ID)
