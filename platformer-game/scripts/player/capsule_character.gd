extends CharacterBody3D

# ---------------------------------------------------------
# Node references
# ---------------------------------------------------------

@onready var animation_player: AnimationPlayer = $Dash/AnimationPlayer
@onready var dash_timer: Timer = $Dash/DashTimer
@onready var dash_cooldown_timer: Timer = $Dash/DashCooldownTimer
@onready var ray_cast_left: RayCast3D = $Raycasts/RayCast3DLeft
@onready var ray_cast_right: RayCast3D = $Raycasts/RayCast3DRight
@onready var visuals: Node3D = $Visuals
@onready var camera_pivot: Node3D = $Node3D
@onready var camera_3d: Camera3D = $Node3D/Camera3D
@onready var stats: Node = $StatsManager

# ---------------------------------------------------------
# Jump constants
# ---------------------------------------------------------

const COYOTE_TIME = 0.12
const JUMP_BUFFER_TIME = 0.12

# ---------------------------------------------------------
# Wall-run constants
# ---------------------------------------------------------

const WALL_RUN_GROUP = "wall_run"
const WALL_RUN_REENTRY_LOCK_TIME := 0.18
const WALL_RUN_VISUAL_TILT_DEGREES := 18.0
const WALL_RUN_VISUAL_TILT_LERP := 12.0

# ---------------------------------------------------------
# Slide contants
# ---------------------------------------------------------

const SLIDE_VISUAL_TILT_DEGREES := -15.0
const SLIDE_VISUAL_TILT_LERP := 10.0

# ---------------------------------------------------------
# Camera constants
# ---------------------------------------------------------

const CAMERA_PITCH_MIN := -85.0
const CAMERA_PITCH_MAX := 85.0

const CAMERA_DISTANCE_MIN := 0.0   # First person
const CAMERA_DISTANCE_MAX := 6.0   # Third person
const CAMERA_SCROLL_STEP  := 0.5   # Distance per scroll
const CAMERA_ZOOM_LERP    := 12.0  # Zoom smoothness

# Wall-run camera lock
const WALL_RUN_CAMERA_DISTANCE   := 2.75
const WALL_RUN_CAMERA_PITCH      := -4.0
const WALL_RUN_CAMERA_YAW_OFFSET := 5.0
const WALL_RUN_CAMERA_LERP       := 6.0
const WALL_RUN_CAMERA_MIN_NORMAL_ANGLE := 5.0

# ---------------------------------------------------------
# Runtime state
# ---------------------------------------------------------

var is_dashing := false
var can_dash := true
var dash_direction := Vector3.ZERO

var is_wall_running := false
var wall_run_timer := 0.0
var wall_run_reentry_timer := 0.0
var current_wall_normal := Vector3.ZERO
var current_wall_direction := Vector3.ZERO
var current_wall_side := 0
var current_wall_collider: Node = null

var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var extra_jumps_left := 0
var can_cut_current_jump := false

var controls_locked := false

var boost_locked := false
var boost_lock_timer := 0.0

# For a smooth zoom
var camera_distance_target := 2.235  # Initial value = Current Z of the camera

var wall_run_camera_yaw := 0.0
var wall_run_camera_pitch := 0.0
var pre_wall_run_camera_distance := 2.235

# For manual pause/resume of dash timers
var paused_dash_time_left := 0.0
var paused_dash_cooldown_time_left := 0.0
var dash_timer_was_running := false
var dash_cooldown_was_running := false

# Slide
var is_sliding = false
var slide_timer = 0.0
var slide_direction = Vector3.ZERO

# ---------------------------------------------------------
# Signals
# ---------------------------------------------------------

signal extra_jumps_changed(current_extra_jumps: int, max_extra_jumps: int)
signal dash_cooldown_started(duration: float)
signal dash_ready()

signal unalive_requested()
signal checkpoint_requested(pos: Vector3)
signal finish_requested()

# ---------------------------------------------------------
# Setup
# ---------------------------------------------------------

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	camera_distance_target = camera_3d.position.z
	extra_jumps_left = stats.max_extra_jumps.get_int()

func _unhandled_input(event):
	if controls_locked:
		return
		
	# Ignore mouse and zoom while wall running
	if is_wall_running:
		return

	if event is InputEventMouseMotion:
		var sens := SettingsManager.mouse_sensitivity
		var y_dir := -1.0 if SettingsManager.invert_mouse_y else 1.0
		rotate_y(-event.relative.x * 0.003 * sens)
		camera_pivot.rotation_degrees.x = clamp(
			camera_pivot.rotation_degrees.x - event.relative.y * rad_to_deg(0.003) * y_dir,
			CAMERA_PITCH_MIN,
			CAMERA_PITCH_MAX
		)

	elif event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				camera_distance_target -= CAMERA_SCROLL_STEP
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				camera_distance_target += CAMERA_SCROLL_STEP
			camera_distance_target = clamp(camera_distance_target, CAMERA_DISTANCE_MIN, CAMERA_DISTANCE_MAX)

# ---------------------------------------------------------
# Main physics loop
# ---------------------------------------------------------

func _physics_process(delta: float) -> void:
	if controls_locked:
		return
		
	if boost_locked:
		boost_lock_timer -= delta
		if boost_lock_timer <= 0.0:
			boost_locked = false
			
		# Skip all input handling below
		update_air_state(is_on_floor(), delta)
		move_and_slide()
		update_camera_zoom(delta)
		return

	var on_floor := is_on_floor()

	update_wall_run_reentry_timer(delta)
	update_jump_buffer(delta)
	force_wall_rays_update()
	update_wall_run_state(on_floor)

	if is_wall_running:
		handle_jump_request(on_floor)

	if not is_wall_running:
		update_air_state(on_floor, delta)
		handle_jump_cut()
		handle_jump_request(on_floor)
		handle_dash_input()
		handle_horizontal_movement(delta, on_floor)
	else:
		handle_dash_input()
		handle_horizontal_movement(delta, false)
		update_wall_run(delta)

	move_and_slide()
	update_visual_tilt(delta)
	update_camera_zoom(delta)

# ---------------------------------------------------------
# Camera update
# ---------------------------------------------------------

func update_camera_zoom(delta: float) -> void:
	if is_wall_running:
		_update_wall_run_camera(delta)
	else:
		camera_3d.position.z = lerp(
			camera_3d.position.z,
			camera_distance_target,
			min(1.0, CAMERA_ZOOM_LERP * delta)
		)
		
func _update_wall_run_camera(delta: float) -> void:
	var t = min(1.0, WALL_RUN_CAMERA_LERP * delta)
	
	rotation_degrees.y = lerp_angle(
		rotation_degrees.y,
		wall_run_camera_yaw,
		t
	)
	
	camera_pivot.rotation_degrees.x = lerp(
		camera_pivot.rotation_degrees.x,
		WALL_RUN_CAMERA_PITCH,
		t
	)
	
	camera_3d.position.z = lerp(
		camera_3d.position.z,
		WALL_RUN_CAMERA_DISTANCE,
		t
	)

func _clamp_wall_run_yaw_to_normal(wall_normal: Vector3) -> void:
	var normal_yaw_deg := rad_to_deg(atan2(wall_normal.x, wall_normal.z))
	var max_delta := 90.0 - WALL_RUN_CAMERA_MIN_NORMAL_ANGLE
	
	var target_delta := wrapf(wall_run_camera_yaw - normal_yaw_deg, -180.0, 180.0)
	if abs(target_delta) > max_delta:
		wall_run_camera_yaw = normal_yaw_deg + clampf(target_delta, -max_delta, max_delta)
	
	var current_delta := wrapf(rotation_degrees.y - normal_yaw_deg, -180.0, 180.0)
	if abs(current_delta) > max_delta:
		rotation_degrees.y = normal_yaw_deg + clampf(current_delta, -max_delta, max_delta)

# ---------------------------------------------------------
# Gravity / floor state
# ---------------------------------------------------------

func update_air_state(on_floor: bool, delta: float) -> void:
	var previous_extra_jumps := extra_jumps_left

	if on_floor:
		coyote_timer = COYOTE_TIME
		extra_jumps_left = stats.max_extra_jumps.get_int()
		can_cut_current_jump = false
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)
		velocity += get_gravity() * delta * stats.gravity_modifier.get_val()

	if velocity.y <= 0.0:
		can_cut_current_jump = false

	if extra_jumps_left != previous_extra_jumps:
		extra_jumps_changed.emit(extra_jumps_left, stats.max_extra_jumps.get_int())

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

	if is_wall_running:
		do_wall_jump()
		jump_buffer_timer = 0.0
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
		extra_jumps_changed.emit(extra_jumps_left, stats.max_extra_jumps.get_int())

func handle_jump_cut() -> void:
	# Variable jump applied only to first jump
	if Input.is_action_just_released("jump") and can_cut_current_jump and velocity.y > 0.0:
		velocity.y *= stats.jump_cut_multiplier.get_val()
		can_cut_current_jump = false

func do_ground_jump() -> void:
	velocity.y = stats.ground_jump_velocity.get_val()
	can_cut_current_jump = true

func do_extra_jump() -> void:
	velocity.y = stats.extra_jump_velocity.get_val()
	can_cut_current_jump = false

func do_wall_jump() -> void:
	var jump_wall_normal := current_wall_normal
	var jump_wall_direction := current_wall_direction

	var carry_speed = max(get_horizontal_speed(), stats.wall_run_speed.get_val() * 0.5)
	var jump_horizontal = jump_wall_direction * carry_speed + jump_wall_normal * stats.wall_jump_away_speed.get_val()

	stop_wall_run()
	wall_run_reentry_timer = WALL_RUN_REENTRY_LOCK_TIME

	velocity.x = jump_horizontal.x
	velocity.z = jump_horizontal.z
	velocity.y = stats.wall_jump_up_velocity.get_val()

	can_cut_current_jump = false
	reset_extra_jumps()

# ---------------------------------------------------------
# Horizontal movement
# ---------------------------------------------------------

func handle_horizontal_movement(delta: float, on_floor: bool) -> void:
	if is_wall_running:
		return

	if is_dashing:
		velocity.x = dash_direction.x * stats.dash_speed.get_val()
		velocity.z = dash_direction.z * stats.dash_speed.get_val()
		return
		
	if on_floor and Input.is_action_just_pressed("Slide") and get_horizontal_speed() > 0.1:
		start_slide()
		
	if is_sliding:
		handle_slide(delta)
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var is_sprinting := Input.is_action_pressed("sprint")
	var target_speed = stats.walk_speed.get_val()
	var accel = stats.ground_accel.get_val()

	if is_sprinting:
		target_speed = stats.sprint_speed.get_val()
		accel = stats.ground_sprint_accel.get_val()
		update_animation_state("sprinting")
	else:
		update_animation_state("walking")

	if not on_floor:
		accel *= stats.air_accel_mult.get_val()

	apply_ground_movement(direction, target_speed, accel, delta)

func apply_ground_movement(direction: Vector3, move_speed: float, accel: float, delta: float) -> void:
	var current_horizontal := Vector3(velocity.x, 0, velocity.z)

	if direction != Vector3.ZERO:
		var target_horizontal := direction * move_speed
		var same_general_direction := current_horizontal.dot(target_horizontal) > 0.0

		if same_general_direction:
			current_horizontal = current_horizontal.move_toward(target_horizontal, accel * delta)
		else:
			current_horizontal = current_horizontal.move_toward(target_horizontal, stats.ground_brake_decel.get_val() * delta)
	else:
		current_horizontal = current_horizontal.move_toward(Vector3.ZERO, stats.ground_decel.get_val() * delta)

	velocity.x = current_horizontal.x
	velocity.z = current_horizontal.z

# ---------------------------------------------------------
# Wall run
# ---------------------------------------------------------

func update_wall_run_state(on_floor: bool) -> void:
	if is_wall_running:
		if on_floor or not refresh_wall_run_contact():
			stop_wall_run()
		return

	if on_floor:
		return

	if wall_run_reentry_timer > 0.0:
		return

	if get_horizontal_speed() < stats.wall_run_min_horizontal_speed.get_val():
		return

	var candidate := get_wall_run_candidate()
	if candidate.is_empty():
		return

	start_wall_run(candidate["normal"], candidate["side"], candidate["collider"])

func start_wall_run(normal: Vector3, side: int, collider: Node) -> void:
	is_wall_running = true
	wall_run_timer = 0.0
	current_wall_normal = normal
	current_wall_side = side
	current_wall_collider = collider
	current_wall_direction = get_wall_run_direction(normal, get_wall_run_reference_vector())

	coyote_timer = 0.0
	can_cut_current_jump = false
	reset_extra_jumps()
	cancel_dash_for_wall_run()
	
	pre_wall_run_camera_distance = camera_distance_target
	var wall_forward_angle := atan2(current_wall_direction.x, current_wall_direction.z)
	wall_run_camera_yaw = rad_to_deg(wall_forward_angle) + WALL_RUN_CAMERA_YAW_OFFSET * float(-side)
	
	_clamp_wall_run_yaw_to_normal(current_wall_normal)

func stop_wall_run() -> void:
	is_wall_running = false
	wall_run_timer = 0.0
	current_wall_normal = Vector3.ZERO
	current_wall_direction = Vector3.ZERO
	current_wall_side = 0
	current_wall_collider = null
	update_visual_tilt(0)
	camera_distance_target = pre_wall_run_camera_distance

func update_wall_run(delta: float) -> void:
	wall_run_timer += delta

	current_wall_direction = get_wall_run_direction(current_wall_normal, get_wall_run_reference_vector())

	var target_horizontal = current_wall_direction * stats.wall_run_speed.get_val()
	target_horizontal += -current_wall_normal * stats.wall_run_inward_speed.get_val()

	var current_horizontal := Vector3(velocity.x, 0, velocity.z)
	current_horizontal = current_horizontal.move_toward(
		Vector3(target_horizontal.x, 0, target_horizontal.z), 
		stats.wall_run_accel.get_val() * delta
	)

	velocity.x = current_horizontal.x
	velocity.z = current_horizontal.z

	if wall_run_timer <= stats.wall_run_stick_duration.get_val():
		velocity.y = move_toward(velocity.y, 0.0, stats.wall_run_vertical_damp.get_val())
	else:
		velocity.y = move_toward(
			velocity.y, 
			-stats.wall_run_slide_speed.get_val(), 
			stats.wall_run_slide_speed.get_val() * delta
		)

func refresh_wall_run_contact() -> bool:
	var candidate := get_wall_run_candidate()
	if candidate.is_empty():
		return false

	current_wall_normal = candidate["normal"]
	current_wall_side = candidate["side"]
	current_wall_collider = candidate["collider"]
	return true

func get_wall_run_candidate() -> Dictionary:
	var candidates := []

	if ray_cast_left != null:
		candidates.append({"ray": ray_cast_left, "side": 1})
	if ray_cast_right != null:
		candidates.append({"ray": ray_cast_right, "side": -1})

	var reference := get_wall_run_reference_vector()
	var best_candidate: Dictionary = {}
	var best_score := -1000000.0

	for candidate in candidates:
		var ray: RayCast3D = candidate["ray"]
		var side: int = candidate["side"]

		if not ray.is_colliding():
			continue

		var collider = ray.get_collider()
		if collider == null or not (collider is Node):
			continue

		var collider_node: Node = collider
		if not collider_node.is_in_group(WALL_RUN_GROUP):
			continue

		var normal := ray.get_collision_normal().normalized()
		var direction := get_wall_run_direction(normal, reference)

		var score := 0.0
		if reference.length_squared() > 0.001:
			score = direction.dot(reference.normalized())

			if score > best_score:
				best_score = score
				best_candidate = {
					"collider": collider_node,
					"normal": normal,
					"side": side
				}
	return best_candidate

func get_wall_run_reference_vector() -> Vector3:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	if input_dir != Vector2.ZERO:
		var world_input := transform.basis * Vector3(input_dir.x, 0, input_dir.y)
		if world_input.length_squared() > 0.001:
			return world_input.normalized()

	var horizontal_velocity := Vector3(velocity.x, 0, velocity.z)
	if horizontal_velocity.length_squared() > 0.001:
		return horizontal_velocity.normalized()

	return -transform.basis.z.normalized()

func get_wall_run_direction(normal: Vector3, reference: Vector3) -> Vector3:
	var flat_reference := Vector3(reference.x, 0, reference.z)
	var projected := flat_reference - normal * flat_reference.dot(normal)
	projected.y = 0.0

	if projected.length_squared() > 0.001:
		return projected.normalized()

	# Fallback for jumps straight into the wall
	var tangent := Vector3.UP.cross(normal).normalized()
	var facing := -transform.basis.z.normalized()

	if tangent.dot(facing) < 0.0:
		tangent = -tangent

	return tangent

func force_wall_rays_update() -> void:
	if ray_cast_left != null:
		ray_cast_left.force_raycast_update()
	if ray_cast_right != null:
		ray_cast_right.force_raycast_update()

func update_wall_run_reentry_timer(delta: float) -> void:
	wall_run_reentry_timer = max(wall_run_reentry_timer - delta, 0.0)

func reset_extra_jumps() -> void:
	if extra_jumps_left == stats.max_extra_jumps.get_int():
		return

	extra_jumps_left = stats.max_extra_jumps.get_int()
	extra_jumps_changed.emit(extra_jumps_left, stats.max_extra_jumps.get_int())

func get_horizontal_speed() -> float:
	return Vector3(velocity.x, 0, velocity.z).length()

# ---------------------------------------------------------
# Dash
# ---------------------------------------------------------

func handle_dash_input() -> void:
	if is_wall_running:
		return

	if Input.is_action_just_pressed("dash") and can_dash:
		start_dash()

func start_dash() -> void:
	is_dashing = true
	can_dash = false

	var input_dir := Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	dash_direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	dash_timer.start()
	dash_cooldown_timer.start()

	dash_cooldown_started.emit(dash_cooldown_timer.wait_time)

	update_animation_state("dashing")

func cancel_dash_for_wall_run() -> void:
	if not is_dashing:
		return

	is_dashing = false
	dash_timer.stop()
	clamp_post_dash_velocity()
	update_animation_state("RESET")

func clamp_post_dash_velocity() -> void:
	var horizontal := Vector3(velocity.x, 0, velocity.z)
	var horizontal_speed := horizontal.length()

	if horizontal_speed > stats.post_dash_speed.get_val():
		horizontal = horizontal.normalized() * stats.post_dash_speed.get_val()
		velocity.x = horizontal.x
		velocity.z = horizontal.z

func _on_dash_timer_timeout() -> void:
	is_dashing = false
	clamp_post_dash_velocity()
	update_animation_state("RESET")

func _on_dash_cooldown_timer_timeout() -> void:
	can_dash = true
	dash_ready.emit()
	
# ---------------------------------------------------------
# Slide
# ---------------------------------------------------------

func start_slide() -> void:
	is_sliding = true
	slide_timer = stats.slide_duration.get_val()
	
	slide_direction = Vector3(velocity.x, 0, velocity.z).normalized()
	
	if slide_direction == Vector3.ZERO:
		slide_direction = -transform.basis.z
		
	velocity.x = slide_direction.x * stats.slide_speed_boost.get_val()
	velocity.z = slide_direction.z * stats.slide_speed_boost.get_val()
	
	var tween = create_tween()
	tween.tween_property(visuals, "scale", Vector3(1.0, 0.5, 1.0), 0.2)
	
func stop_slide() -> void:
	is_sliding = false
	var tween = create_tween()
	tween.tween_property(visuals, "scale", Vector3(1.0, 1.0, 1.0), 0.2)
	visuals.rotation.z = 0.0
	
func handle_slide(delta: float) -> void:
	slide_timer -= delta
	
	if Input.is_action_just_pressed("jump"):
		stop_slide()
		return
		
	var current_horizontal := Vector3(velocity.x, 0, velocity.z)
	current_horizontal = current_horizontal.move_toward(Vector3.ZERO, stats.slide_decel.get_val() * delta)
	
	velocity.x = current_horizontal.x
	velocity.z = current_horizontal.z
	
	if slide_timer <= 0 or get_horizontal_speed() < stats.walk_speed.get_val():
		stop_slide()

# ---------------------------------------------------------
# Animation / Visual
# ---------------------------------------------------------

func update_animation_state(animation_name: String) -> void:
	if animation_player.current_animation != animation_name and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)

func _on_animation_player_animation_changed(old_name: StringName, new_name: StringName) -> void:
	print("Animation changed from: " + old_name + " to " + new_name)

func update_visual_tilt(delta: float) -> void:
	if visuals == null:
		return
		
	var target_roll := 0.0
	if is_wall_running:
		target_roll = deg_to_rad(WALL_RUN_VISUAL_TILT_DEGREES) * -float(current_wall_side)
	elif is_sliding:
		target_roll = deg_to_rad(SLIDE_VISUAL_TILT_DEGREES)

	visuals.rotation.z = lerp_angle(
		visuals.rotation.z,
		target_roll,
		min(1.0, (WALL_RUN_VISUAL_TILT_LERP if is_wall_running else SLIDE_VISUAL_TILT_LERP) * delta)
	)

# ---------------------------------------------------------
# Requests to level
# ---------------------------------------------------------

func request_unalive() -> void:
	unalive_requested.emit()

func request_checkpoint(pos: Vector3) -> void:
	checkpoint_requested.emit(pos)

func request_finish() -> void:
	finish_requested.emit()

# ---------------------------------------------------------
# Level-controlled player state
# ---------------------------------------------------------

func apply_boost(boost_velocity: Vector3, lock_duration: float = 0.0) -> void:
	if is_dashing:
		is_dashing = false
		dash_timer.stop()
	if is_wall_running:
		stop_wall_run()
		
	velocity = boost_velocity
	
	if lock_duration > 0.0:
		boost_locked = true
		boost_lock_timer = lock_duration

func teleport_to_position(pos: Vector3) -> void:
	global_position = pos

func reset_movement_state() -> void:
	velocity = Vector3.ZERO

	is_dashing = false
	can_dash = true
	dash_direction = Vector3.ZERO

	stop_wall_run()
	wall_run_reentry_timer = 0.0

	dash_timer.stop()
	dash_cooldown_timer.stop()

	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	extra_jumps_left = stats.max_extra_jumps.get_int()
	can_cut_current_jump = false

	if visuals != null:
		visuals.rotation.z = 0.0

	extra_jumps_changed.emit(extra_jumps_left, stats.max_extra_jumps.get_int())
	dash_ready.emit()

func respawn_at(pos: Vector3) -> void:
	teleport_to_position(pos)
	reset_movement_state()

func lock_controls() -> void:
	controls_locked = true
	velocity = Vector3.ZERO
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func unlock_controls() -> void:
	controls_locked = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func pause_timers() -> void:
	dash_timer_was_running = not dash_timer.is_stopped()
	dash_cooldown_was_running = not dash_cooldown_timer.is_stopped()

	if dash_timer_was_running:
		paused_dash_time_left = dash_timer.time_left
		dash_timer.stop()

	if dash_cooldown_was_running:
		paused_dash_cooldown_time_left = dash_cooldown_timer.time_left
		dash_cooldown_timer.stop()

func resume_timers() -> void:
	if dash_timer_was_running and paused_dash_time_left > 0.0:
		dash_timer.start(paused_dash_time_left)

	if dash_cooldown_was_running and paused_dash_cooldown_time_left > 0.0:
		dash_cooldown_timer.start(paused_dash_cooldown_time_left)

	dash_timer_was_running = false
	dash_cooldown_was_running = false
	paused_dash_time_left = 0.0
	paused_dash_cooldown_time_left = 0.0

# ---------------------------------------------------------
# Helpers
# ---------------------------------------------------------

func emit_initial_ui_state() -> void:
	extra_jumps_changed.emit(extra_jumps_left, stats.max_extra_jumps.get_int())
	dash_ready.emit()
