class_name PlayerStat

var base_value: float
var bonus_value: float = 0.0

func _init(base: float):
	base_value = base

func get_val() -> float:
	return base_value + bonus_value

func get_int() -> int:
	return int(get_val())
