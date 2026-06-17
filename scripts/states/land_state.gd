class_name LandState
extends State

const LAND_ANIM_THRESHOLD := 3.5
var _done: bool = false

var state_name := "LandState"

func enter() -> void:
	_done = false
	var fall_speed = player.last_fall_speed
	var came_from_jump = state_machine.previous_state is JumpState

	if fall_speed < LAND_ANIM_THRESHOLD and not came_from_jump:
		_done = true
		return

	player.velocity.x = 0.0
	player.velocity.z = 0.0
	player.anim_player.play("Stash 2/Jump_Land", -1, 1.0)
	player.anim_player.animation_finished.connect(_on_anim_finished, CONNECT_ONE_SHOT)

func _on_anim_finished(_anim_name: String) -> void:
	_done = true

func physics_process(delta: float) -> void:
	player.apply_gravity(delta)
	player.move_and_slide()

	# If the player immediately pushes a direction, skip the land anim entirely
	var dir = player.get_movement_input()
	if dir.length() > 0.1:
		if player.is_sprinting:
			state_machine.transition_to(state_machine.get_node("RunState"))
		else:
			state_machine.transition_to(state_machine.get_node("WalkState"))
		return

	if Input.is_action_just_pressed("jump"):
		state_machine.transition_to(state_machine.get_node("JumpState"))
		return

	if _done:
		state_machine.transition_to(state_machine.get_node("IdleState"))
