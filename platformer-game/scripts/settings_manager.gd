extends Node

signal settings_applied

const SAVE_PATH := "user://settings.cfg"

# ---- Audio ----
# non functional examples
const AUDIO_BUSES := ["Master", "Music", "SFX"]

# ---- Controls ----
const EXCLUDED_ACTIONS := []

# ---- Display ----
const RESOLUTIONS := [
	Vector2i(1152, 648),
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

const FPS_CAPS := [0, 30, 60, 90, 120, 144, 240]

enum AAMode { OFF, FXAA, MSAA_2X, MSAA_4X, MSAA_8X }

# ---- Defaults ----
var ghost_replay = true

var audio_volumes := {}
var audio_muted := {}

var mouse_sensitivity := 1.0
var invert_mouse_y := false

var fullscreen := false
var resolution_index := 0
var vsync := true
var aa_mode: int = AAMode.FXAA
var fps_cap_index := 2
var pixelization_enabled := false
var pixelization_scale := 0.5

var key_bindings := {}

func _ready() -> void:
	for bus_name in AUDIO_BUSES:
		audio_volumes[bus_name] = 1.0
		audio_muted[bus_name] = false
		
	load_settings()
	apply_all()
	
func apply_all() -> void:
	apply_audio()
	apply_display()
	apply_key_bindings()
	settings_applied.emit()
	
# ===============================================================
# General
# ===============================================================

func set_ghost_replay(value: bool) -> void:
	ghost_replay = value
	save_settings()
	
func get_ghost_replay() -> bool:
	return ghost_replay

# ===============================================================
# Audio
# ===============================================================

func set_bus_volume(bus_name: String, linear_value: float) -> void:
	audio_volumes[bus_name] = clampf(linear_value, 0.0, 1.0)
	_apply_bus_volume(bus_name)
	save_settings()
	
func set_bus_muted(bus_name: String, muted: bool) -> void:
	audio_muted[bus_name] = muted
	_apply_bus_volume(bus_name)
	save_settings()

func _apply_bus_volume(bus_name: String) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	var linear: float = audio_volumes.get(bus_name, 1.0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(linear))
	AudioServer.set_bus_mute(idx, audio_muted.get(bus_name, false))
	
func apply_audio() -> void:
	for bus_name in AUDIO_BUSES:
		_apply_bus_volume(bus_name)

# ===============================================================
# Display
# ===============================================================

func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_fullscreen()
	save_settings()
	
func _apply_fullscreen() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_apply_resolution()
		
func set_resolution_index(index: int) -> void:
	resolution_index = clampi(index, 0, RESOLUTIONS.size() - 1)
	_apply_resolution()
	save_settings()
		
func _apply_resolution() -> void:
	if fullscreen:
		return
	var size: Vector2i = RESOLUTIONS[resolution_index]
	get_window().size = size
	var screen_size := DisplayServer.screen_get_size()
	DisplayServer.window_set_position((screen_size - size) / 2)

func set_vsync(enabled: bool) -> void:
	vsync = enabled
	_apply_vsync()
	save_settings()
	
func _apply_vsync() -> void:
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		
func set_aa_mode(mode: int) -> void:
	aa_mode = mode
	_apply_aa()
	save_settings()
	
func _apply_aa() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	match aa_mode:
		AAMode.OFF:
			viewport.msaa_3d = Viewport.MSAA_DISABLED
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		AAMode.FXAA:
			viewport.msaa_3d = Viewport.MSAA_DISABLED
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		AAMode.MSAA_2X:
			viewport.msaa_3d = Viewport.MSAA_2X
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		AAMode.MSAA_4X:
			viewport.msaa_3d = Viewport.MSAA_4X
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		AAMode.MSAA_8X:
			viewport.msaa_3d = Viewport.MSAA_8X
			viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			
func set_fps_cap_index(index: int) -> void:
	fps_cap_index = clampi(index, 0, FPS_CAPS.size() - 1)
	_apply_fps_cap()
	save_settings()
	
func _apply_fps_cap() -> void:
	Engine.max_fps = FPS_CAPS[fps_cap_index]
	
func set_pixelization(enabled: bool, scale: float = -1.0) -> void:
	pixelization_enabled = enabled
	if scale > 0.0:
		pixelization_scale = clampf(scale, 0.1, 1.0)
	_apply_pixelization()
	save_settings()
	
func _apply_pixelization() -> void:
	# Simple approximation
	var viewport := get_viewport()
	if viewport == null:
		return
	if pixelization_enabled:
		viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		viewport.scaling_3d_scale = pixelization_scale
	else:
		viewport.scaling_3d_scale = 1.0
		
func apply_display() -> void:
	_apply_vsync()
	_apply_fps_cap()
	_apply_fullscreen()
	_apply_aa()
	_apply_pixelization()

# ===============================================================
# Controls
# ===============================================================

func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = value
	save_settings()
	
func set_invert_mouse_y(enabled: bool) -> void:
	invert_mouse_y = enabled
	save_settings()
	
func rebind_action(action_name: String, event: InputEvent) -> void:
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, event)
	key_bindings[action_name] = [event]
	save_settings()
	
func reset_action_to_default(action_name: String) -> void:
	InputMap.action_erase_events(action_name)
	if ProjectSettings.has_setting("input/" + action_name):
		var data: Dictionary = ProjectSettings.get_setting("input/" + action_name)
		for e in data.get("events", []):
			InputMap.action_add_event(action_name, e)
	key_bindings.erase(action_name)
	save_settings()
	
func apply_key_bindings() -> void:
	for action_name in key_bindings.keys():
		if not InputMap.has_action(action_name):
			continue
		InputMap.action_erase_events(action_name)
		for event in key_bindings[action_name]:
			InputMap.action_add_event(action_name, event)
			
# ===============================================================
# Reset sections
# ===============================================================

func reset_audio_to_defaults() -> void:
	for bus_name in AUDIO_BUSES:
		audio_volumes[bus_name] = 1.0
		audio_muted[bus_name] = false
	apply_audio()
	save_settings()

func reset_controls_to_defaults() -> void:
	mouse_sensitivity = 1.0
	invert_mouse_y = false
	for action_name in key_bindings.keys().duplicate():
		reset_action_to_default(action_name)
	key_bindings.clear()
	save_settings()

func reset_display_to_defaults() -> void:
	fullscreen = false
	resolution_index = 3
	vsync = true
	aa_mode = AAMode.FXAA
	fps_cap_index = 2
	pixelization_enabled = false
	pixelization_scale = 0.5
	apply_display()
	save_settings()

# ===============================================================
# Reset all
# ===============================================================

func reset_to_defaults() -> void:
	ghost_replay = true

	for bus_name in AUDIO_BUSES:
		audio_volumes[bus_name] = 1.0
		audio_muted[bus_name] = false

	mouse_sensitivity = 1.0
	invert_mouse_y = false
	
	fullscreen = false
	resolution_index = 3
	vsync = true
	aa_mode = AAMode.FXAA
	fps_cap_index = 2
	pixelization_enabled = false
	pixelization_scale = 0.5
	
	for action_name in key_bindings.keys().duplicate():
		reset_action_to_default(action_name)
	key_bindings.clear()
	
	apply_all()
	save_settings()
	
# ===============================================================
# Persistence
# ===============================================================

func _event_to_dict(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {
			"type": "key",
			"keycode": event.physical_keycode if event.physical_keycode != 0 else event.keycode
			}
	elif event is InputEventMouseButton:
		return {
			"type": "mouse_button",
			"button_index": event.button_index
		}
	elif event is InputEventJoypadButton:
		return {
			"type": "joy_button",
			"button_index": event.button_index
		}
	elif event is InputEventJoypadMotion:
		return {
			"type": "joy_motion",
			"axis": event.axis,
			"axis_value": event.axis_value
		}
	return {}
	
func _dict_to_event(data: Dictionary):
	match data.get("type", ""):
		"key":
			var e := InputEventKey.new()
			e.physical_keycode = data.get("keycode", 0)
			return e
		"mouse_button":
			var e := InputEventMouseButton.new()
			e.button_index = data.get("button_index", 0)
			return e
		"joy_button":
			var e := InputEventJoypadButton.new()
			e.button_index = data.get("button_index", 0)
			return e
		"joy_motion":
			var e := InputEventJoypadMotion.new()
			e.axis = data.get("axis", 0)
			e.axis_value = data.get("axis_value", 0.0)
			return e
	return null
	
func save_settings() -> void:
	var config := ConfigFile.new()
	
	for bus_name in AUDIO_BUSES:
		config.set_value("audio", bus_name + "_volume", audio_volumes.get(bus_name, 1.0))
		config.set_value("audio", bus_name + "_muted", audio_muted.get(bus_name, false))

	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("controls", "invert_mouse_y", invert_mouse_y)
	
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "resolution_index", resolution_index)
	config.set_value("display", "vsync", vsync)
	config.set_value("display", "aa_mode", aa_mode)
	config.set_value("display", "fps_cap_index", fps_cap_index)
	config.set_value("display", "pixelization_enabled", pixelization_enabled)
	config.set_value("display", "pixelization_scale", pixelization_scale)
	
	for action_name in key_bindings.keys():
		var events: Array = key_bindings[action_name]
		var serialized: Array = []
		for e in events:
			serialized.append(_event_to_dict(e))
		config.set_value("key_bindings", action_name, serialized)
		
	config.save(SAVE_PATH)
	
func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err != OK:
		return
		
	for bus_name in AUDIO_BUSES:
		audio_volumes[bus_name] = config.get_value("audio", bus_name + "_volume", 1.0)
		audio_muted[bus_name] = config.get_value("audio", bus_name + "_muted", false)
		
	mouse_sensitivity = config.get_value("controls", "mouse_sensitivity", 1.0)
	invert_mouse_y = config.get_value("controls", "invert_mouse_y", false)
	
	fullscreen = config.get_value("display", "fullscreen", false)
	resolution_index = config.get_value("display", "resolution_index", 3)
	vsync = config.get_value("display", "vsync", true)
	aa_mode = config.get_value("display", "aa_mode", AAMode.FXAA)
	fps_cap_index = config.get_value("display", "fps_cap_index", 2)
	pixelization_enabled = config.get_value("display", "pixelization_enabled", false)
	pixelization_scale = config.get_value("display", "pixelization_scale", 0.5)
	
	if config.has_section("key_bindings"):
		for action_name in config.get_section_keys("key_bindings"):
			var serialized: Array = config.get_value("key_bindings", action_name, [])
			var events: Array = []
			for d in serialized:
				var e = _dict_to_event(d)
				if e != null:
					events.append(e)
			key_bindings[action_name] = events
