extends CharacterBody3D

# Movement
const WALK_SPEED = 5.0
const SPRINT_SPEED = 9.0
const DASH_SPEED = 20.0
const JUMP_VELOCITY = 4.5

# Animations / Timers
@onready var animation_player: AnimationPlayer = $Dash/AnimationPlayer
@onready var dash_timer: Timer = $Dash/DashTimer
@onready var dash_cooldown_timer: Timer = $Dash/DashCooldownTimer
@onready var double_tap_timer: Timer = $Dash/DoubleTapTimer

var is_dashing := false
var can_dash := true
var waiting_for_second_tap := false
var dash_direction := Vector3.ZERO

# Mouse movement
const MOUSE_SENSITIVITY = 0.003

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	# Sprint / dash input
	handle_sprint_and_dash_input()

	# Movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_dashing:
		velocity.x = dash_direction.x * DASH_SPEED
		velocity.z = dash_direction.z * DASH_SPEED
	else:
		var is_sprinting = Input.is_action_pressed("sprint")
		var current_speed := WALK_SPEED
		
		if is_sprinting:
			current_speed = SPRINT_SPEED
			update_animation_state("sprinting")
		else:
			update_animation_state("walking")
			
		if direction:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
	
func handle_sprint_and_dash_input() -> void:
	if Input.is_action_just_pressed("sprint"):
		if waiting_for_second_tap and can_dash:
			start_dash()
			waiting_for_second_tap = false
			double_tap_timer.stop()
		else:
			waiting_for_second_tap = true
			double_tap_timer.start()
	
func start_dash() -> void:
	is_dashing = true
	can_dash = false
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	dash_direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	dash_timer.start()
	dash_cooldown_timer.start()
	
	update_animation_state("dashing")
		
func update_animation_state(animation_name: String) -> void:
	if animation_player.current_animation != animation_name and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)

func _on_dash_timer_timeout() -> void:
	is_dashing = false
		
	update_animation_state("RESET")
		
func _on_dash_cooldown_timer_timeout() -> void:
	can_dash = true

func _on_double_tap_timer_timeout() -> void:
	waiting_for_second_tap = false

func _on_animation_player_animation_changed(old_name: StringName, new_name: StringName) -> void:
	print("Animation changed from: " + old_name + " to " + new_name)
