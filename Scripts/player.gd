class_name Player
extends CharacterBody3D

const GRAVITY := 9.8
const WALK_SPEED := 4.0
const RUN_SPEED := 8.0
const JUMP_VELOCITY := 5.0
const ROTATION_SPEED := 10.0

@onready var _camera : Camera3D = %Camera3D
@onready var _camera_pivot_yaw : Node3D = %CameraPivotYaw
@onready var _camera_pivot_pitch: Node3D = %CameraPivotPitch
@onready var state_machine: StateMachine = $StateMachine
@onready var player_model: Node3D = $Mesh

@export_range(0.0, 1.0) var mouse_sensitivity = 0.0025
@export var tilt_limit = deg_to_rad(75)

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	state_machine.init(self)

func _input(event: InputEvent) -> void:
	state_machine.handle_input(event)
	if event is InputEventMouseMotion:
		_camera_pivot_yaw.rotate_y(-event.relative.x * mouse_sensitivity)
		_camera_pivot_pitch.rotate_x(-event.relative.y * mouse_sensitivity)
		_camera_pivot_pitch.rotation.x = clamp(_camera_pivot_pitch.rotation.x, -0.6, 0.4)

func _process(delta: float) -> void:
	state_machine.process(delta)
	
func _physics_process(delta: float) -> void:
	state_machine.physics_process(delta)

func get_movement_input() -> Vector3:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	var forward = -_camera_pivot_yaw.global_transform.basis.z
	var right = _camera_pivot_yaw.global_transform.basis.x
	
	forward.y = 0
	forward = forward.normalized()
	right.y = 0
	right = right.normalized()
	
	return (forward * -input_dir.y + right * input_dir.x)

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
