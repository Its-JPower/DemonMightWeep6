class_name Player
extends CharacterBody3D

const GRAVITY := 9.8
const WALK_SPEED := 4.0
const RUN_SPEED := 8.0
const JUMP_VELOCITY := 5.0
const ROTATION_SPEED := 6.7
const ACCELERATION := 15.0
const DECELERATION := 20.0

@onready var _camera : Camera3D = %Camera3D
@onready var _camera_pivot_yaw : Node3D = %CameraPivotYaw
@onready var _camera_pivot_pitch: Node3D = %CameraPivotPitch
@onready var state_machine: StateMachine = $StateMachine
@onready var player_model: Node3D = $Mesh

@export_range(0.0, 1.0) var mouse_sensitivity = 0.0025
@export var tilt_limit = deg_to_rad(75)

var is_aiming = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	state_machine.init(self)

func _input(event: InputEvent) -> void:
	state_machine.handle_input(event)
	if event is InputEventMouseMotion:
		if is_aiming:
			rotate_y(-event.relative.x * mouse_sensitivity)
		else:
			_camera_pivot_yaw.rotate_y(-event.relative.x * mouse_sensitivity)
		_camera_pivot_pitch.rotate_x(-event.relative.y * mouse_sensitivity)
		_camera_pivot_pitch.rotation.x = clamp(_camera_pivot_pitch.rotation.x, -0.6, 0.4)
	if Input.is_action_just_pressed("aim"):
		is_aiming = true
	if Input.is_action_just_released("aim"):
		is_aiming = false

func _process(delta: float) -> void:
	state_machine.process(delta)
	
func _physics_process(delta: float) -> void:
	state_machine.physics_process(delta)
	if is_aiming:
		rotate_model_toward_camera(delta)
	else:
		rotate_model_toward_movement(delta)

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
	var target_speed = RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED

	if direction.length() > 0.1:
		# Accelerate toward target velocity
		var target_velocity = direction * target_speed
		velocity.x = move_toward(velocity.x, target_velocity.x, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, ACCELERATION * delta)
	else:
		# Decelerate to a stop
		velocity.x = move_toward(velocity.x, 0.0, DECELERATION * delta)
		velocity.z = move_toward(velocity.z, 0.0, DECELERATION * delta)

func rotate_model_toward_movement(delta: float) -> void:
	var direction = get_movement_input()
	
	if direction.length() > 0.1:
		var target_basis = Basis.looking_at(direction, Vector3.UP)
		player_model.global_basis = player_model.global_basis.slerp(target_basis, ROTATION_SPEED * delta)

func rotate_model_toward_camera(delta: float) -> void:
	var target_basis = Basis.looking_at(-_camera_pivot_yaw.global_transform.basis.z, Vector3.UP)
	player_model.global_basis = player_model.global_basis.slerp(target_basis, ROTATION_SPEED * delta)
