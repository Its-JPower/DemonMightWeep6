class_name Player
extends CharacterBody3D

@onready var _camera : Camera3D = %Camera3D
@onready var _camera_pivot_yaw : Node3D = %CameraPivotYaw
@onready var _camera_pivot_pitch: Node3D = %CameraPivotPitch
@onready var _spring_arm : SpringArm3D = %SpringArm
@onready var player_model: Node3D = $Mesh
@onready var anim_player: AnimationPlayer = $Mesh/AnimationPlayer
@onready var state_machine: StateMachine = $StateMachine

@export_range(0.0, 1.0) var mouse_sensitivity = 0.0025
@export var tilt_limit = deg_to_rad(75)

@export var lock_on_timeout := 3.0        # seconds of no attack before dropping lock
@export var lock_on_cam_speed := 5.0      # how fast camera swings to target

@export var shake_decay := 5.0            # how fast camera shake settles back to zero

@export var hit_sfx: Array[AudioStream] = []
@export var hit_sfx_pitch_range := Vector2(0.95, 1.05)
@onready var _hit_sfx_player: AudioStreamPlayer3D = %HitSFXPlayer

@export var kill_sfx: Array[AudioStream] = []
@export var enemy_sfx: Array[AudioStream] = []
@export var sfx_pitch_range := Vector2(0.95, 1.05)

signal health_changed(current: float, max: float)
signal died
signal run_summary_ready(result: Dictionary)

@export var max_health: float = 100.0
@export var hit_shake_strength: float = 0.15
@export var invuln_time: float = 0.5
@export var knockback_friction: float = 40.0
@export var post_hit_invuln_time: float = 2.0   # brief invuln granted after landing a hit on an enemy

@export var hurt_state: State
@export var death_state: State

@export_group("Healing")
@export var health_regen_rate: float = 0.0      # HP restored per second once regen kicks in (0 = disabled)
@export var health_regen_delay: float = 3.0     # seconds since last damage taken before regen starts
@export var kill_heal_amount: float = 30       # flat HP restored per enemy kill (0 = disabled)

var health: float
var _invuln_timer: float = 0.0
var _time_since_damage: float = 0.0
var knockback_velocity: Vector3 = Vector3.ZERO

var lock_on_target: Node3D = null         # currently locked enemy
var _lock_on_idle_timer := 0.0            # counts up when not attacking

var GRAVITY := 9.8
var WALK_SPEED := 4.0
var RUN_SPEED := 8.0
var JUMP_VELOCITY := 5.0
var ROTATION_SPEED := 6.7
var ACCELERATION := 15.0
var DECELERATION := 20.0
var SPECIALING_IT_SPEED := 2.0

const JOY_SENSITIVITY := 2.5

const PIVOT_HEIGHT := 1.6
const PIVOT_WALL_MARGIN := 0.35
const PIVOT_LERP_SPEED := 20.0

enum RotationMode { MOVEMENT, CAMERA, LOCKED }
var rotation_mode := RotationMode.MOVEMENT
var is_sprinting = false
var is_aiming = false
var is_specialing_it = false
var _joy_look := Vector2.ZERO
var last_fall_speed
var last_rotation_mode := RotationMode.MOVEMENT
var _realigning_camera := false
var _realign_timer := 0.0
const REALIGN_DURATION := 0.3

var _shake_strength := 0.0
var _run_saved := false        # guards against saving the leaderboard entry twice

func _ready() -> void:
	health = max_health
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	state_machine.init(self)
	_fix_ual1_tracks()
	_run_saved = false
	Score.start_run()

func take_damage(amount: float, knockback_dir: Vector3 = Vector3.ZERO, knockback_strength: float = 0.0) -> void:
	if _invuln_timer > 0.0:
		return
	health = max(health - amount, 0.0)
	health_changed.emit(health, max_health)
	Score.register_damage(amount)
	_time_since_damage = 0.0
	camera_shake(hit_shake_strength)
	play_hit_sfx()
	_invuln_timer = invuln_time
	knockback_velocity = knockback_dir * knockback_strength
	if health <= 0.0:
		died.emit()
		finish_run()
		state_machine.transition_to(death_state)
	else:
		state_machine.transition_to(hurt_state)

## Ends the run and emits the summary for UI (e.g. a game-over popup) to
## display and save. Safe to call more than once (e.g. once from death,
## once from a "quit to menu" button) — only the first call does anything.
## Returns the result dict (empty {} if already finished) so callers that
## don't show a popup can save a fallback entry themselves, e.g.:
##   Leaderboard.add_entry("Player", player.finish_run())
func finish_run() -> Dictionary:
	if _run_saved:
		return {}
	_run_saved = true
	var result := Score.end_run()
	run_summary_ready.emit(result)
	return result

## duration defaults to post_hit_invuln_time, but callers (attack states)
## can pass a longer window for heavier hits, e.g. Slash C.
func register_hit_landed(duration: float = post_hit_invuln_time) -> void:
	_invuln_timer = max(_invuln_timer, duration)

## Restores health, clamped to max_health. Emits health_changed like normal
## damage/heal changes do, so the health bar UI updates automatically.
func heal(amount: float) -> void:
	if amount <= 0.0 or health <= 0.0:
		return
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)

## Call this from an enemy's death handler (they already hold a `player`
## reference) to grant the on-kill heal.
func heal_on_kill() -> void:
	heal(kill_heal_amount)

func play_hit_sfx() -> void:
	_play_one_shot(hit_sfx)

func play_kill_sfx() -> void:
	_play_one_shot(kill_sfx)

func _play_one_shot(pool: Array[AudioStream]) -> void:
	if pool.is_empty():
		return
	var p := AudioStreamPlayer3D.new()
	add_child(p)
	p.stream = pool.pick_random()
	p.pitch_scale = randf_range(sfx_pitch_range.x, sfx_pitch_range.y)
	p.finished.connect(p.queue_free)
	p.play()

func play_hit_sfx_enemy() -> void:
	_play_one_shot(enemy_sfx)

func _fix_ual1_tracks() -> void:
	for lib_name in anim_player.get_animation_library_list():
		var lib = anim_player.get_animation_library(lib_name)
		for anim_name in lib.get_animation_list():
			var anim = lib.get_animation(anim_name)
			for i in anim.get_track_count():
				var path = str(anim.track_get_path(i))
				if path.begins_with("Armature/"):
					anim.track_set_path(i, path.replace("Armature/", ""))

func _input(event: InputEvent) -> void:
	state_machine.handle_input(event)
	if event is InputEventMouseMotion:
		_camera_pivot_yaw.rotate_y(-event.relative.x * mouse_sensitivity)
		_camera_pivot_pitch.rotate_x(-event.relative.y * mouse_sensitivity)
		_camera_pivot_pitch.rotation.x = clamp(_camera_pivot_pitch.rotation.x, -0.6, 0.4)
	elif event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_RIGHT_X:
			_joy_look.x = event.axis_value
		elif event.axis == JOY_AXIS_RIGHT_Y:
			_joy_look.y = event.axis_value
	if Input.is_action_just_pressed("cam_lock"):
		is_aiming = !is_aiming
		rotation_mode = RotationMode.CAMERA if is_aiming else RotationMode.MOVEMENT
	if Input.is_action_just_pressed("run"):
		is_sprinting = !is_sprinting
	if Input.is_action_just_pressed("special"):
		if rotation_mode != RotationMode.LOCKED:
			last_rotation_mode = rotation_mode
		rotation_mode = RotationMode.CAMERA
		is_specialing_it = true
	if Input.is_action_just_released("special"):
		rotation_mode = last_rotation_mode if lock_on_target == null else RotationMode.LOCKED
		is_specialing_it = false
	if Input.is_action_just_pressed("lock_on"):
		if lock_on_target != null:
			_drop_lock_on()

func _process(delta: float) -> void:
	state_machine.process(delta)
	if _joy_look.length() > 0.1:  # deadzone
		_camera_pivot_yaw.rotate_y(-_joy_look.x * JOY_SENSITIVITY * delta)
		_camera_pivot_pitch.rotate_x(-_joy_look.y * JOY_SENSITIVITY * delta)
		_camera_pivot_pitch.rotation.x = clamp(_camera_pivot_pitch.rotation.x, -0.6, 0.4)

	if _shake_strength > 0.01:
		_camera.h_offset = randf_range(-1.0, 1.0) * _shake_strength
		_camera.v_offset = randf_range(-1.0, 1.0) * _shake_strength
		_shake_strength = move_toward(_shake_strength, 0.0, shake_decay * delta)
	else:
		_camera.h_offset = 0.0
		_camera.v_offset = 0.0

func camera_shake(strength: float) -> void:
	_shake_strength = max(_shake_strength, strength)

func _physics_process(delta: float) -> void:
	if _invuln_timer > 0.0:
		_invuln_timer -= delta
	_time_since_damage += delta
	if health_regen_rate > 0.0 and health > 0.0 and health < max_health \
			and _time_since_damage >= health_regen_delay:
		heal(health_regen_rate * delta)
	knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, knockback_friction * delta)
	if velocity.y < 0:
		last_fall_speed = -velocity.y
	state_machine.physics_process(delta)
	_update_camera_pivot(delta)

	if _realigning_camera:
		_realign_timer += delta
		var forward := -player_model.global_transform.basis.z
		var target_yaw := atan2(-forward.x, -forward.z)
		_camera_pivot_yaw.global_rotation.y = lerp_angle(
			_camera_pivot_yaw.global_rotation.y, target_yaw,
			_realign_timer / REALIGN_DURATION)
		if _realign_timer >= REALIGN_DURATION:
			_realigning_camera = false
		_update_lock_on(delta)
		return

	match rotation_mode:
		RotationMode.MOVEMENT: rotate_model_toward_movement(delta)
		RotationMode.CAMERA:   rotate_model_toward_camera(delta)
		RotationMode.LOCKED:   pass
	_update_lock_on(delta)

func _update_camera_pivot(delta: float) -> void:
	var current_yaw := _camera_pivot_yaw.global_rotation.y
	var desired := global_position + Vector3.UP * PIVOT_HEIGHT
	var safe := _push_from_walls(desired)
	_camera_pivot_yaw.global_position = _camera_pivot_yaw.global_position.lerp(safe, PIVOT_LERP_SPEED * delta)
	_camera_pivot_yaw.global_rotation.y = current_yaw

func _push_from_walls(origin: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var mask := _spring_arm.collision_mask
	var exclude := [self.get_rid()]
	var result_pos := origin

	for dir in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		var params := PhysicsRayQueryParameters3D.new()
		params.from = origin
		params.to = origin + dir * PIVOT_WALL_MARGIN
		params.collision_mask = mask
		params.exclude = exclude
		var hit := space.intersect_ray(params)
		if hit:
			var dist := origin.distance_to(hit.position)
			result_pos -= dir * (PIVOT_WALL_MARGIN - dist)

	return result_pos

func get_movement_input() -> Vector3:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var forward = -_camera_pivot_yaw.global_transform.basis.z
	var right = _camera_pivot_yaw.global_transform.basis.x
	forward.y = 0
	forward = forward.normalized()
	right.y = 0
	right = right.normalized()
	return (forward * -input_dir.y + right * input_dir.x).normalized()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

func apply_movement(delta: float) -> void:
	var direction = get_movement_input()
	var target_speed: float
	if is_sprinting:
		target_speed = RUN_SPEED
	elif is_specialing_it:
		target_speed = SPECIALING_IT_SPEED
	else:
		target_speed = WALK_SPEED

	if direction.length() > 0.1:
		var target_velocity = direction * target_speed
		velocity.x = move_toward(velocity.x, target_velocity.x, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, DECELERATION * delta)
		velocity.z = move_toward(velocity.z, 0.0, DECELERATION * delta)

func rotate_model_toward_movement(delta: float) -> void:
	var direction = get_movement_input()
	var rotate_toward: Vector3
	if direction.length() > 0.1:
		rotate_toward = direction
	else:
		var horizontal_velocity = Vector3(velocity.x, 0.0, velocity.z)
		if horizontal_velocity.length() > 0.1:
			rotate_toward = horizontal_velocity.normalized()
		else:
			return
	var target_basis = Basis.looking_at(rotate_toward, Vector3.UP)
	player_model.global_basis = player_model.global_basis.slerp(target_basis, ROTATION_SPEED * delta)

func set_lock_on_target(enemy: Node3D) -> void:
	if lock_on_target == null:
		if rotation_mode != RotationMode.LOCKED and not is_specialing_it:
			last_rotation_mode = rotation_mode
			print("saved last_rotation_mode as: ", last_rotation_mode)
	lock_on_target = enemy
	_lock_on_idle_timer = 0.0
	rotation_mode = RotationMode.LOCKED

func _update_lock_on(delta: float) -> void:
	if lock_on_target == null:
		return

	if not is_instance_valid(lock_on_target):
		_drop_lock_on()
		return

	_lock_on_idle_timer += delta
	if _lock_on_idle_timer >= lock_on_timeout:
		_drop_lock_on()
		return

	var to_target := lock_on_target.global_position - _camera_pivot_yaw.global_position

	# --- Yaw ---
	var to_target_flat := Vector3(to_target.x, 0.0, to_target.z)
	if to_target_flat.length() < 0.01:
		return
	var target_yaw := atan2(-to_target_flat.x, -to_target_flat.z)
	_camera_pivot_yaw.global_rotation.y = lerp_angle(
		_camera_pivot_yaw.global_rotation.y, target_yaw, lock_on_cam_speed * delta)

	# --- Pitch ---
	var dist_flat := to_target_flat.length()
	var target_pitch := atan2(to_target.y, dist_flat)
	_camera_pivot_pitch.rotation.x = lerp_angle(
		_camera_pivot_pitch.rotation.x,
		clamp(target_pitch, -0.6, 0.4),  # same clamp limits as your manual look
		lock_on_cam_speed * delta)

	# --- Model facing ---
	var target_basis := Basis.looking_at(to_target_flat.normalized(), Vector3.UP)
	player_model.global_basis = player_model.global_basis.slerp(target_basis, ROTATION_SPEED * delta)

func _drop_lock_on() -> void:
	print("dropping lock on, last_rotation_mode: ", last_rotation_mode)
	print("current rotation_mode: ", rotation_mode)
	lock_on_target = null
	rotation_mode = last_rotation_mode
	print("rotation_mode after drop: ", rotation_mode)
	_realigning_camera = true
	_realign_timer = 0.0

func get_camera_forward() -> Vector3:
	var forward = -_camera_pivot_yaw.global_transform.basis.z
	forward.y = 0
	return forward.normalized()

func rotate_model_toward_camera(delta: float) -> void:
	if _realigning_camera:
		_realign_timer += delta
		var t := _realign_timer / REALIGN_DURATION

		# Swing camera yaw toward player's current facing
		var forward := -player_model.global_transform.basis.z
		var target_yaw := atan2(-forward.x, -forward.z)
		_camera_pivot_yaw.global_rotation.y = lerp_angle(
			_camera_pivot_yaw.global_rotation.y, target_yaw, t)

		if _realign_timer >= REALIGN_DURATION:
			_realigning_camera = false
		return

	# Normal camera mode rotation
	var forward := -_camera_pivot_yaw.global_transform.basis.z
	forward.y = 0
	if forward.length() < 0.01:
		return
	var target_basis := Basis.looking_at(forward, Vector3.UP)
	player_model.global_basis = player_model.global_basis.slerp(target_basis, ROTATION_SPEED * delta)
