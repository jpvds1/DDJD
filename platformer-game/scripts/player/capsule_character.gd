extends CharacterBody3D

# ---------------------------------------------------------
# Movement constants
# ---------------------------------------------------------

const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const DASH_SPEED = 50.0
const POST_DASH_SPEED = 10.0

const GROUND_ACCEL = 24.0
const GROUND_SPRINT_ACCEL = 32.0
const GROUND_DECEL = 20.0
const GROUND_BRAKE_DECEL = 38.0
const AIR_ACCEL_MULT = 0.6

const GRAVITY_MODIFIER = 1.2
const MOUSE_SENSITIVITY = 0.003

# ---------------------------------------------------------
# Jump constants
# ---------------------------------------------------------

const GROUND_JUMP_VELOCITY = 7.5
const EXTRA_JUMP_VELOCITY = 5.5
const JUMP_CUT_MULTIPLIER = 0.45

const MAX_EXTRA_JUMPS = 1
const COYOTE_TIME = 0.12
const JUMP_BUFFER_TIME = 0.12

# ---------------------------------------------------------
# Survival constants
# ---------------------------------------------------------

const MAX_LIVES = 3

# ---------------------------------------------------------
# Runtime state
# ---------------------------------------------------------

var is_dashing := false
var can_dash := true
var dash_direction := Vector3.ZERO

var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var extra_jumps_left := MAX_EXTRA_JUMPS
var can_cut_current_jump := false

var last_checkpoint_position: Vector3
var has_checkpoint := false

var lives := MAX_LIVES

# ---------------------------------------------------------
# Node references
# ---------------------------------------------------------

@onready var animation_player: AnimationPlayer = $Dash/AnimationPlayer
@onready var dash_timer: Timer = $Dash/DashTimer
@onready var dash_cooldown_timer: Timer = $Dash/DashCooldownTimer

# ---------------------------------------------------------
# Signals
# ---------------------------------------------------------

signal lives_changed(current_lives: int, max_lives: int)
signal dash_state_changed(can_dash_now: bool)
signal extra_jumps_changed(current_extra_jumps: int, max_extra_jumps: int)

signal checkpoint_reached()
signal player_unalived()
signal end_reached()

# ---------------------------------------------------------
# Setup
# ---------------------------------------------------------

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	last_checkpoint_position = global_position
	has_checkpoint = true

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)

# ---------------------------------------------------------
# Main physics loop
# ---------------------------------------------------------

func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()
	
	update_air_state(on_floor, delta)
	update_jump_buffer(delta)
	handle_jump_cut()
	handle_jump_request(on_floor)
			
	handle_dash_input()
	handle_horizontal_movement(delta, on_floor)

	move_and_slide()
	
# ---------------------------------------------------------
# Gravity / floor state
# ---------------------------------------------------------	

func update_air_state(on_floor: bool, delta: float) -> void:
	var previous_extra_jumps := extra_jumps_left
	
	if on_floor:
		coyote_timer = COYOTE_TIME
		extra_jumps_left = MAX_EXTRA_JUMPS
		can_cut_current_jump = false
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)
		velocity += get_gravity() * delta * GRAVITY_MODIFIER
	
	if velocity.y <= 0.0:
		can_cut_current_jump = false
		
	if extra_jumps_left != previous_extra_jumps:
		extra_jumps_changed.emit(extra_jumps_left, MAX_EXTRA_JUMPS)

# ---------------------------------------------------------
# Jump input and execution
# ---------------------------------------------------------

func update_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta,  0.0)
		
func handle_jump_request(on_floor: bool) -> void:
	if jump_buffer_timer <= 0.0:
		return
		
	# Ground jump when on the ground or on coyote time
	# Extra jump consumed after that
	if on_floor or coyote_timer > 0.0:
		do_ground_jump()
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
	elif extra_jumps_left > 0:
		do_extra_jump()
		extra_jumps_left -= 1
		jump_buffer_timer = 0.0
		extra_jumps_changed.emit(extra_jumps_left, MAX_EXTRA_JUMPS)
		
func handle_jump_cut() -> void:
	# Variable jump applied only to first jump
	if Input.is_action_just_released("jump") and can_cut_current_jump and velocity.y > 0.0:
		velocity.y *= JUMP_CUT_MULTIPLIER
		can_cut_current_jump = false

func do_ground_jump() -> void:
	velocity.y = GROUND_JUMP_VELOCITY
	can_cut_current_jump = true

func do_extra_jump() -> void:
	velocity.y = EXTRA_JUMP_VELOCITY
	can_cut_current_jump = false
	
# ---------------------------------------------------------
# Horizontal movement
# ---------------------------------------------------------

func handle_horizontal_movement(delta: float, on_floor: bool) -> void:
	if is_dashing:
		velocity.x = dash_direction.x * DASH_SPEED
		velocity.z = dash_direction.z * DASH_SPEED
		return
		
	var input_dir := Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var is_sprinting := Input.is_action_pressed("sprint")
	var target_speed := WALK_SPEED
	var accel := GROUND_ACCEL

	if is_sprinting:
		target_speed = SPRINT_SPEED
		accel = GROUND_SPRINT_ACCEL
		update_animation_state("sprinting")
	else:
		update_animation_state("walking")
		
	if not on_floor:
		accel *= AIR_ACCEL_MULT

	apply_ground_movement(direction, target_speed, accel, delta)
	
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
	
# ---------------------------------------------------------
# Dash
# ---------------------------------------------------------

func handle_dash_input() -> void:
	if Input.is_action_just_pressed("dash") and can_dash:
		start_dash()	

func start_dash() -> void:
	is_dashing = true
	can_dash = false
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	dash_direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
	dash_timer.start()
	dash_cooldown_timer.start()
	
	dash_state_changed.emit(can_dash)
	update_animation_state("dashing")

func clamp_post_dash_velocity() -> void:
	var horizontal := Vector3(velocity.x, 0, velocity.z)
	var horizontal_speed := horizontal.length()

	if horizontal_speed > POST_DASH_SPEED:
		horizontal = horizontal.normalized() * POST_DASH_SPEED
		velocity.x = horizontal.x
		velocity.z = horizontal.z
		
func _on_dash_timer_timeout() -> void:
	is_dashing = false
	clamp_post_dash_velocity()
	update_animation_state("RESET")
		
func _on_dash_cooldown_timer_timeout() -> void:
	can_dash = true
	dash_state_changed.emit(can_dash)
	
# ---------------------------------------------------------
# Animation
# ---------------------------------------------------------
		
func update_animation_state(animation_name: String) -> void:
	if animation_player.current_animation != animation_name and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
		
func _on_animation_player_animation_changed(old_name: StringName, new_name: StringName) -> void:
	print("Animation changed from: " + old_name + " to " + new_name)
		
# ---------------------------------------------------------
# Checkpoint / respawn
# ---------------------------------------------------------		

func set_checkpoint(pos: Vector3) -> void:
	last_checkpoint_position = pos
	has_checkpoint = true
	checkpoint_reached.emit()
	
func respawn() -> void:
	if not has_checkpoint:
		return

	global_position = last_checkpoint_position
	velocity = Vector3.ZERO

	is_dashing = false
	can_dash = true
	dash_direction = Vector3.ZERO
	dash_timer.stop()
	dash_cooldown_timer.stop()

	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	extra_jumps_left = MAX_EXTRA_JUMPS
	can_cut_current_jump = false
	
	dash_state_changed.emit(can_dash)
	extra_jumps_changed.emit(extra_jumps_left, MAX_EXTRA_JUMPS)
	
func unalive() -> void:
	lives = max(lives - 1, 0)
	player_unalived.emit()
	lives_changed.emit(lives, MAX_LIVES)
	respawn()
	
func reach_end() -> void:
	end_reached.emit()
	
# ---------------------------------------------------------
# Helpers
# ---------------------------------------------------------		

func emit_initial_ui_state() -> void:
	lives_changed.emit(lives, MAX_LIVES)
	dash_state_changed.emit(can_dash)
	extra_jumps_changed.emit(extra_jumps_left, MAX_EXTRA_JUMPS)
