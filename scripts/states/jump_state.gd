class_name JumpState
extends State

var state_name := "JumpState"

var jumps_remaining := 0
const PEAK_THRESHOLD := 1.5
const PEAK_WINDOW := 0.4
const FALL_THRESHOLD := -0.5
var peak_reached := false
var peak_timer := 0.0
var jump_consumed := false

func enter() -> void:
	player.anim_player.play("Stash 2/Jump_Start", -1, 1.0)
	player.velocity.y = player.JUMP_VELOCITY
	jumps_remaining = 1
	peak_reached = false
	peak_timer = 0.0
	jump_consumed = true

func physics_process(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_movement(delta)
	player.move_and_slide()

	if jump_consumed and not Input.is_action_pressed("jump"):
		jump_consumed = false

	if not peak_reached and player.velocity.y < PEAK_THRESHOLD:
		peak_reached = true

	if peak_reached:
		peak_timer += delta

	# Land check — go through LandState for impact polish
	if player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("LandState"))
		return

	if peak_reached and peak_timer >= PEAK_WINDOW:
		state_machine.transition_to(state_machine.get_node("FallState"))

func handle_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("jump") and not jump_consumed:
		jump_consumed = true
		if jumps_remaining > 0 and peak_reached:
			player.anim_player.play("Stash 2/Jump_Start", -1, 1.0)
			player.velocity.y = player.JUMP_VELOCITY
			jumps_remaining -= 1
			peak_reached = false
			peak_timer = 0.0

	if Input.is_action_just_pressed("attack"):
		if player.is_specialing_it:
			state_machine.transition_to(state_machine.get_node("DownSlamState"))
		else:
			state_machine.transition_to(state_machine.get_node("AirSlashAState"))
	if Input.is_action_just_pressed("jump") and player.is_specialing_it:
		state_machine.transition_to(state_machine.get_node("RisingSlashState"))
