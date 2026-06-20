extends Node

# ---------------------------------------------------------
# Movement constants
# ---------------------------------------------------------

var walk_speed          := PlayerStat.new(6.5)
var sprint_speed        := PlayerStat.new(10.5)
var dash_speed          := PlayerStat.new(50.0)
var post_dash_speed     := PlayerStat.new(10.0)
var dash_cooldown       := PlayerStat.new(1.5)
var max_dashes          := PlayerStat.new(1)

var ground_accel        := PlayerStat.new(24.0)
var ground_sprint_accel := PlayerStat.new(32.0)
var ground_decel        := PlayerStat.new(39.0)
var ground_brake_decel  := PlayerStat.new(55.0)
var air_accel_mult      := PlayerStat.new(0.6)

var gravity_modifier    := PlayerStat.new(1.65)

# ---------------------------------------------------------
# Jump constants
# ---------------------------------------------------------

var ground_jump_velocity := PlayerStat.new(7.5)
var extra_jump_velocity  := PlayerStat.new(5.5)
var jump_cut_multiplier  := PlayerStat.new(0.45)
var max_extra_jumps      := PlayerStat.new(2.0)

# ---------------------------------------------------------
# Wall-run constants
# ---------------------------------------------------------

var wall_run_min_horizontal_speed := PlayerStat.new(5.0)
var wall_run_speed                := PlayerStat.new(12.5)
var wall_run_accel                := PlayerStat.new(38.0)
var wall_run_stick_duration       := PlayerStat.new(1.0)
var wall_run_vertical_damp        := PlayerStat.new(18.0)
var wall_run_slide_speed          := PlayerStat.new(4.5)
var wall_run_slide_accel          := PlayerStat.new(8.5)
var wall_run_inward_speed         := PlayerStat.new(2.0)
var wall_jump_up_velocity         := PlayerStat.new(7.0)
var wall_jump_away_speed          := PlayerStat.new(7.5)

# ---------------------------------------------------------
# Methods
# ---------------------------------------------------------

func _ready() -> void:
	GlobalInventory.equipment_changed.connect(recalculate_bonuses)
	recalculate_bonuses()	
	
func recalculate_bonuses():
	_reset_all_bonuses()
	
	for slot in GlobalInventory.equipped_gear:
		var item: GearItem = GlobalInventory.equipped_gear[slot]
		if item == null:
			continue
			
		walk_speed.bonus_value         += item.speed_bonus
		sprint_speed.bonus_value       += item.speed_bonus
		
		ground_accel.bonus_value        += item.acceleration_bonus
		ground_sprint_accel.bonus_value += item.acceleration_bonus
		
		ground_jump_velocity.bonus_value += item.jump_velocity_bonus
		extra_jump_velocity.bonus_value  += item.jump_velocity_bonus
		
		max_extra_jumps.bonus_value      += float(item.extra_jumps)
		
		dash_cooldown.bonus_value        -= item.dash_cooldown_reduction
		max_dashes.bonus_value           += float(item.extra_dashes)

	var active_set := GlobalInventory.get_active_set()
	if active_set:
		walk_speed.bonus_value           += active_set.speed_bonus
		sprint_speed.bonus_value         += active_set.speed_bonus
		ground_accel.bonus_value         += active_set.acceleration_bonus
		ground_sprint_accel.bonus_value  += active_set.acceleration_bonus
		ground_jump_velocity.bonus_value += active_set.jump_velocity_bonus
		extra_jump_velocity.bonus_value  += active_set.jump_velocity_bonus
		max_extra_jumps.bonus_value      += float(active_set.extra_jumps)
		dash_cooldown.bonus_value        -= active_set.dash_cooldown_reduction
		max_dashes.bonus_value           += float(active_set.extra_dashes)

func _reset_all_bonuses() -> void:
	walk_speed.bonus_value                    = 0.0
	sprint_speed.bonus_value                  = 0.0
	dash_speed.bonus_value                    = 0.0
	post_dash_speed.bonus_value               = 0.0
	dash_cooldown.bonus_value                 = 0.0
	max_dashes.bonus_value                    = 0.0
	ground_accel.bonus_value                  = 0.0
	ground_sprint_accel.bonus_value           = 0.0
	ground_decel.bonus_value                  = 0.0
	ground_brake_decel.bonus_value            = 0.0
	air_accel_mult.bonus_value                = 0.0
	gravity_modifier.bonus_value              = 0.0
	ground_jump_velocity.bonus_value          = 0.0
	extra_jump_velocity.bonus_value           = 0.0
	jump_cut_multiplier.bonus_value           = 0.0
	max_extra_jumps.bonus_value               = 0.0
	wall_run_min_horizontal_speed.bonus_value = 0.0
	wall_run_speed.bonus_value                = 0.0
	wall_run_accel.bonus_value                = 0.0
	wall_run_stick_duration.bonus_value       = 0.0
	wall_run_vertical_damp.bonus_value        = 0.0
	wall_run_slide_speed.bonus_value          = 0.0
	wall_run_slide_accel.bonus_value          = 0.0
	wall_run_inward_speed.bonus_value         = 0.0
	wall_jump_up_velocity.bonus_value         = 0.0
	wall_jump_away_speed.bonus_value          = 0.0
