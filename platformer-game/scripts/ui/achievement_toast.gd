extends PanelContainer

@onready var name_label: Label = $MarginContainer/VBox/NameLabel

const WIDTH := 280.0
const GAP := 20.0
const SLIDE_DURATION := 0.35
const HOLD := 3.0

var _tween: Tween

var _slide_x: float = WIDTH + GAP:
	set(v):
		_slide_x = v
		offset_right = v
		offset_left = v - WIDTH

func _ready() -> void:
	_slide_x = WIDTH + GAP
	$MarginContainer/VBox/HeaderLabel.add_theme_color_override("font_color", Palette.TEXT_DIM)
	GlobalInventory.achievement_unlocked.connect(_show_achievement)

func _show_achievement(achievement_id: String) -> void:
	name_label.text = achievement_id.replace("_", " ").capitalize()
	if _tween:
		_tween.kill()
	_slide_x = WIDTH + GAP
	_tween = create_tween()
	_tween.tween_property(self, "_slide_x", -GAP, SLIDE_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_interval(HOLD)
	_tween.tween_property(self, "_slide_x", WIDTH + GAP, SLIDE_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
