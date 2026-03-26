extends CharacterBody3D

# Movement
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const DASH_SPEED = 50.0
const JUMP_VELOCITY = 7.5
const GRAVITY_MODIFIER = 1.2
const POST_DASH_SPEED = 10.0

# Acceleration
const GROUND_ACCEL = 24.0
const GROUND_SPRINT_ACCEL = 32.0
const GROUND_DECEL = 20.0
const GROUND_BRAKE_DECEL = 38.0

# Double jump
const MAX_EXTRA_JUMPS = 1
const COYOTE_TIME = 0.12
const JUMP_BUFFER_TIME = 0.12
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var extra_jumps_available := MAX_EXTRA_JUMPS

# Animations / Timers
@onready var animation_player: AnimationPlayer = $Dash/AnimationPlayer
@onready var dash_timer: Timer = $Dash/DashTimer
@onready var dash_cooldown_timer: Timer = $Dash/DashCooldownTimer

var is_dashing := false
var can_dash := true
var dash_direction := Vector3.ZERO

# Respawn / Checkpoints
var last_checkpoint_position: Vector3
var has_checkpoint := false

# Mouse movement
const MOUSE_SENSITIVITY = 0.003

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	last_checkpoint_position = global_position
	has_checkpoint = true

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)

func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()
	
	# Resets when landing
	if on_floor:
		coyote_timer = COYOTE_TIME
		extra_jumps_available = true
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)
		velocity += get_gravity() * delta * GRAVITY_MODIFIER

	# Jump buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)
		
	# Buffered jump execution
	if jump_buffer_timer > 0.0:
		if on_floor or coyote_timer > 0.0:
			do_jump()
			coyote_timer = 0.0
			jump_buffer_timer = 0.0
		elif extra_jumps_available > 0:
			do_jump()
			extra_jumps_available -= 1
			jump_buffer_timer = 0.0
		
	# Sprint / dash input
	if Input.is_action_just_pressed("dash") and can_dash:
		start_dash()

	# Movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_dashing:
		velocity.x = dash_direction.x * DASH_SPEED
		velocity.z = dash_direction.z * DASH_SPEED
	else:
		var is_sprinting := Input.is_action_pressed("sprint")
		var current_speed := WALK_SPEED
		var current_accel := GROUND_ACCEL

		if is_sprinting:
			current_speed = SPRINT_SPEED
			current_accel = GROUND_SPRINT_ACCEL
			update_animation_state("sprinting")
		else:
			update_animation_state("walking")

		apply_ground_movement(direction, current_speed, current_accel, delta)

	move_and_slide()
	
func do_jump() -> void:
	velocity.y = JUMP_VELOCITY
	
func apply_ground_movement(direction: Vector3, move_speed: float, accel: float, delta: float) -> void:
	var current_horizontal := Vector3(velocity.x, 0, velocity.z)

	if direction != Vector3.ZERO:
		var target_horizontal := direction * move_speed
		var same_general_direction := current_horizontal.dot(target_horizontal) > 0.0

		if same_general_direction:
			current_horizontal = current_horizontal.move_toward(target_horizontal, accel * delta)
		else:
			current_horizontal = current_horizontal.move_toward(target_horizontal, GROUND_BRAKE_DECEL * delta)
	else:
		current_horizontal = current_horizontal.move_toward(Vector3.ZERO, GROUND_DECEL * delta)

	velocity.x = current_horizontal.x
	velocity.z = current_horizontal.z
	
func clamp_post_dash_velocity() -> void:
	var horizontal := Vector3(velocity.x, 0, velocity.z)
	var horizontal_speed := horizontal.length()

	if horizontal_speed > POST_DASH_SPEED:
		horizontal = horizontal.normalized() * POST_DASH_SPEED
		velocity.x = horizontal.x
		velocity.z = horizontal.z
	
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
		
func set_checkpoint(pos: Vector3) -> void:
	last_checkpoint_position = pos
	has_checkpoint = true
	print("Checkpoint set at: ", pos)
	
func respawn() -> void:
	if not has_checkpoint:
		return
		
	global_position = last_checkpoint_position
	velocity = Vector3.ZERO
	is_dashing = false
	can_dash = true

func _on_dash_timer_timeout() -> void:
	is_dashing = false
	clamp_post_dash_velocity()
	update_animation_state("RESET")
		
func _on_dash_cooldown_timer_timeout() -> void:
	can_dash = true

func _on_animation_player_animation_changed(old_name: StringName, new_name: StringName) -> void:
	print("Animation changed from: " + old_name + " to " + new_name)
