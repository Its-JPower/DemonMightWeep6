class_name JumpState
extends State

var jumps_remaining := 0

const PEAK_THRESHOLD := 1.5
const PEAK_WINDOW := 0.4
const FALL_THRESHOLD := -0.5

var peak_reached := false
var peak_timer := 0.0
var jump_consumed := false  # blocks input until button is released and repressed

func enter() -> void:
	player.rotation_mode = Player.RotationMode.MOVEMENT
	player.velocity.y = player.JUMP_VELOCITY
	jumps_remaining = 1
	peak_reached = false
	peak_timer = 0.0
	jump_consumed = true  # treat the initial jump as already consumed

func physics_process(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_movement(delta)
	player.move_and_slide()

	# Only clear the flag when we physically see the button is up
	if jump_consumed and not Input.is_action_pressed("jump"):
		jump_consumed = false

	if not peak_reached and player.velocity.y < PEAK_THRESHOLD:
		peak_reached = true

	if peak_reached:
		peak_timer += delta

	if player.is_on_floor():
		var dir = player.get_movement_input()
		if dir.length() > 0.1:
			state_machine.transition_to(state_machine.get_node("WalkState"))
		else:
			state_machine.transition_to(state_machine.get_node("IdleState"))
	elif peak_reached and peak_timer >= PEAK_WINDOW:
		state_machine.transition_to(state_machine.get_node("FallState"))

func handle_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("jump") and not jump_consumed:
		jump_consumed = true  # always consume, even if the attempt is invalid
		if jumps_remaining > 0 and peak_reached:
			player.velocity.y = player.JUMP_VELOCITY
			jumps_remaining -= 1
			peak_reached = false
			peak_timer = 0.0
