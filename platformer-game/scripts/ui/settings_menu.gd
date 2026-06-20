extends Control

@onready var back_button: Button = %BackButton
@onready var ghost_replay_checkbox: CheckBox = %GhostReplayCheckbox
@onready var sign_out_button: Button = %SignOut
@onready var reset_defaults_button: Button = %ResetDefaultsButton

@onready var audio_tab: VBoxContainer = %AudioTab
@onready var audio_rows: VBoxContainer = %AudioRows
@onready var reset_audio_button: Button = %ResetAudioButton

@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var sensitivity_value_label: Label = %SensitivityValueLabel
@onready var invert_mouse_checkbox: CheckBox = %InvertMouseCheckBox
@onready var controls_action_list: VBoxContainer = %ActionList

@onready var fullscreen_checkbox: CheckBox = %FullscreenCheckBox
@onready var resolution_option: OptionButton = %ResolutionOption
@onready var vsync_checkbox: CheckBox = %VSyncCheckBox
@onready var aa_option: OptionButton = %AAOption
@onready var fps_cap_option: OptionButton = %FPSCAPOption
@onready var pixelization_checkbox: CheckBox = %PixelizationCheckBox

@onready var rebind_popup: PanelContainer = %RebindPopup
@onready var rebind_popup_label: Label = %RebindPopupLabel

@onready var tab_container: TabContainer = %TabContainer

var _rebinding_action: String = ""
var _action_buttons: Dictionary = {}

func _ready() -> void:
	ghost_replay_checkbox.button_pressed = SettingsManager.get_ghost_replay()
	back_button.pressed.connect(_on_back_button_pressed)
	ghost_replay_checkbox.toggled.connect(_on_ghost_replay_checkbox_toggled)
	sign_out_button.pressed.connect(_on_sign_out_pressed)
	reset_defaults_button.pressed.connect(_on_reset_defaults_pressed)
	reset_audio_button.pressed.connect(_on_reset_audio_pressed)
	
	tab_container.set_tab_title(0, "General")
	tab_container.set_tab_title(1, "Audio")
	tab_container.set_tab_title(2, "Controls")
	tab_container.set_tab_title(3, "Display")
	
	_build_audio_tab()
	_build_controls_tab()
	_setup_display_tab()
	
	rebind_popup.hide()
	
	if !Supabase.is_logged_in():
		sign_out_button.text = "Back to Login"
	
# ============================================================
# General Tab
# ============================================================

func _on_ghost_replay_checkbox_toggled(value: bool) -> void:
	SettingsManager.set_ghost_replay(value)

func _on_reset_defaults_pressed() -> void:
	SettingsManager.reset_to_defaults()
	_build_audio_tab()
	_refresh_controls_tab()
	_refresh_display_tab()
 
 
func _on_sign_out_pressed() -> void:
	if Supabase.is_logged_in():
		await Supabase.sign_out()
	
	Global.game_controller.change_GUI_scene("res://scenes/ui/landing_screen.tscn")

# ============================================================
# AUDIO TAB
# ============================================================

func _on_reset_audio_pressed() -> void:
	SettingsManager.reset_audio_to_defaults()
	_build_audio_tab()

func _build_audio_tab():
	for child in audio_rows.get_children():
		child.queue_free()

	for bus_name in SettingsManager.AUDIO_BUSES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		
		var label := Label.new()
		label.text = bus_name
		label.custom_minimum_size.x = 140
		row.add_child(label)
		
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.value = SettingsManager.audio_volumes.get(bus_name, 1.0)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(slider)
		
		var value_label := Label.new()
		value_label.custom_minimum_size.x = 50
		value_label.text = "%d%%" % int(round(slider.value * 100.0))
		row.add_child(value_label)
		
		var mute_checkbox := CheckBox.new()
		mute_checkbox.text = "Mute"
		mute_checkbox.button_pressed = SettingsManager.audio_muted.get(bus_name, false)
		row.add_child(mute_checkbox)
		
		slider.value_changed.connect(func(v: float):
			value_label.text = "%d%%" % int(round(v * 100.0))
			SettingsManager.set_bus_volume(bus_name, v)	
		)
		mute_checkbox.toggled.connect(func(pressed: bool):
			SettingsManager.set_bus_muted(bus_name, pressed)
		)
		
		audio_rows.add_child(row)
		
# ============================================================
# CONTROLS TAB
# ============================================================

func _build_controls_tab() -> void:
	sensitivity_slider.min_value = 0.1
	sensitivity_slider.max_value = 3.0
	sensitivity_slider.step = 0.05
	sensitivity_slider.value = SettingsManager.mouse_sensitivity
	sensitivity_value_label.text = "%.2fx" % sensitivity_slider.value
 
	sensitivity_slider.value_changed.connect(func(v: float):
		sensitivity_value_label.text = "%.2fx" % v
		SettingsManager.set_mouse_sensitivity(v)
	)
 
	invert_mouse_checkbox.button_pressed = SettingsManager.invert_mouse_y
	invert_mouse_checkbox.toggled.connect(func(pressed: bool):
		SettingsManager.set_invert_mouse_y(pressed)
	)
 
	_build_action_list()

func _build_action_list() -> void:
	for child in controls_action_list.get_children():
		child.queue_free()
	_action_buttons.clear()
 
	for action_name in InputMap.get_actions():
		if action_name.begins_with("ui_"):
			continue
		if action_name in SettingsManager.EXCLUDED_ACTIONS:
			continue
 
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
 
		var label := Label.new()
		label.text = action_name.capitalize()
		label.custom_minimum_size.x = 160
		row.add_child(label)
 
		var bind_button := Button.new()
		bind_button.text = _get_binding_text(action_name)
		bind_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bind_button.pressed.connect(_on_rebind_pressed.bind(action_name))
		row.add_child(bind_button)
 
		var reset_button := Button.new()
		reset_button.text = "Reset"
		reset_button.pressed.connect(func():
			SettingsManager.reset_action_to_default(action_name)
			bind_button.text = _get_binding_text(action_name)
		)
		row.add_child(reset_button)
 
		_action_buttons[action_name] = bind_button
		controls_action_list.add_child(row)

func _get_binding_text(action_name: String) -> String:
	var events := InputMap.action_get_events(action_name)
	if events.is_empty():
		return "Unbound"
	var event := events[0]
	if event is InputEventKey:
		var keycode: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		return OS.get_keycode_string(keycode)
	elif event is InputEventMouseButton:
		return "Mouse " + str(event.button_index)
	elif event is InputEventJoypadButton:
		return "Joy " + str(event.button_index)
	return event.as_text()
 
 
func _on_rebind_pressed(action_name: String) -> void:
	_rebinding_action = action_name
	rebind_popup_label.text = "Press any key for \"%s\"\n(Esc to cancel)" % action_name.capitalize()
	rebind_popup.show()

func _input(event: InputEvent) -> void:
	if _rebinding_action == "":
		if event is InputEventKey and event.physical_keycode == KEY_ESCAPE and event.pressed:
			_go_back()
		return
 
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if event.physical_keycode == KEY_ESCAPE:
			_cancel_rebind()
			return
		SettingsManager.rebind_action(_rebinding_action, event)
		_finish_rebind()
	elif event is InputEventMouseButton and event.pressed:
		get_viewport().set_input_as_handled()
		SettingsManager.rebind_action(_rebinding_action, event)
		_finish_rebind()
	elif event is InputEventJoypadButton and event.pressed:
		get_viewport().set_input_as_handled()
		SettingsManager.rebind_action(_rebinding_action, event)
		_finish_rebind()
 
 
func _finish_rebind() -> void:
	var button: Button = _action_buttons.get(_rebinding_action)
	if button:
		button.text = _get_binding_text(_rebinding_action)
	_cancel_rebind()
 
 
func _cancel_rebind() -> void:
	_rebinding_action = ""
	rebind_popup.hide()

# ============================================================
# DISPLAY TAB
# ============================================================
 
func _setup_display_tab() -> void:
	fullscreen_checkbox.button_pressed = SettingsManager.fullscreen
	fullscreen_checkbox.toggled.connect(func(pressed: bool):
		SettingsManager.set_fullscreen(pressed)
		resolution_option.disabled = pressed
	)
	resolution_option.disabled = SettingsManager.fullscreen
 
	resolution_option.clear()
	for res in SettingsManager.RESOLUTIONS:
		resolution_option.add_item("%dx%d" % [res.x, res.y])
	resolution_option.select(SettingsManager.resolution_index)
	resolution_option.item_selected.connect(func(index: int):
		SettingsManager.set_resolution_index(index)
	)
 
	vsync_checkbox.button_pressed = SettingsManager.vsync
	vsync_checkbox.toggled.connect(func(pressed: bool):
		SettingsManager.set_vsync(pressed)
	)
 
	aa_option.clear()
	aa_option.add_item("Off")
	aa_option.add_item("FXAA")
	aa_option.add_item("MSAA 2x")
	aa_option.add_item("MSAA 4x")
	aa_option.add_item("MSAA 8x")
	aa_option.select(SettingsManager.aa_mode)
	aa_option.item_selected.connect(func(index: int):
		SettingsManager.set_aa_mode(index)
	)
 
	fps_cap_option.clear()
	for fps in SettingsManager.FPS_CAPS:
		fps_cap_option.add_item("Unlimited" if fps == 0 else str(fps))
	fps_cap_option.select(SettingsManager.fps_cap_index)
	fps_cap_option.item_selected.connect(func(index: int):
		SettingsManager.set_fps_cap_index(index)
	)
 
	pixelization_checkbox.button_pressed = SettingsManager.pixelization_enabled
	pixelization_checkbox.toggled.connect(func(pressed: bool):
		SettingsManager.set_pixelization(pressed)
	)
 
 
func _refresh_controls_tab() -> void:
	sensitivity_slider.value = SettingsManager.mouse_sensitivity
	invert_mouse_checkbox.button_pressed = SettingsManager.invert_mouse_y
	for action_name in _action_buttons.keys():
		_action_buttons[action_name].text = _get_binding_text(action_name)
 
 
func _refresh_display_tab() -> void:
	fullscreen_checkbox.button_pressed = SettingsManager.fullscreen
	resolution_option.select(SettingsManager.resolution_index)
	resolution_option.disabled = SettingsManager.fullscreen
	vsync_checkbox.button_pressed = SettingsManager.vsync
	aa_option.select(SettingsManager.aa_mode)
	fps_cap_option.select(SettingsManager.fps_cap_index)
	pixelization_checkbox.button_pressed = SettingsManager.pixelization_enabled
	
# ============================================================
# OTHER
# ============================================================
 
func _go_back() -> void:
	if Global.settings_return_scene == "":
		Global.game_controller.close_gui_scene()
	else:
		Global.game_controller.change_GUI_scene(Global.settings_return_scene)

func _on_back_button_pressed() -> void:
	_go_back()
