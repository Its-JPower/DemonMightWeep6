class_name RunState
extends State

func enter() -> void:
	player.anim_player.play("Stash 2/Sprint", 1.0)

func physics_process(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_movement(delta)
	player.move_and_slide()

	if not player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("FallState"))
		return

	var dir = player.get_movement_input()

	if not player.is_sprinting:
		state_machine.transition_to(state_machine.get_node("WalkState"))
		return

	if dir.length() < 0.1:
		state_machine.transition_to(state_machine.get_node("IdleState"))
		return

	if Input.is_action_just_pressed("jump"):
		state_machine.transition_to(state_machine.get_node("JumpState"))
		return

	# Running attack always triggers AbdomenPiercer — feels like a charge
	if Input.is_action_just_pressed("attack"):
		state_machine.transition_to(state_machine.get_node("AbdomenPiercerState"))
