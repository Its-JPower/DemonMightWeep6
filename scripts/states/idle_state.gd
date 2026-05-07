class_name IdleState
extends State

func enter() -> void:
	player.anim_player.play("Stash 2/Idle", 1.0)
	player.velocity.x = 0
	player.velocity.z = 0
	player.is_sprinting = false

func physics_process(delta: float) -> void:
	player.apply_gravity(delta)
	player.move_and_slide()

	if not player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("JumpState"))
		return

	if not player.is_specialing_it:
		var dir = player.get_movement_input()
		if dir.length() > 0.1:
			if player.is_sprinting:
				state_machine.transition_to(state_machine.get_node("RunState"))
			else:
				state_machine.transition_to(state_machine.get_node("WalkState"))
		if Input.is_action_just_pressed("attack"):
			if state_machine.previous_state == state_machine.get_node("SwordSlashAState"):
				state_machine.transition_to(state_machine.get_node("SwordSlashBState"))
			elif state_machine.previous_state == state_machine.get_node("SwordSlashBState"):
				state_machine.transition_to(state_machine.get_node("SwordSlashCState"))
			else:
				state_machine.transition_to(state_machine.get_node("SwordSlashAState"))
	else:
		if Input.is_action_just_pressed("dance"):
			player.anim_player.play("Stash 2/Dance", 1.0)
		if Input.is_action_just_pressed("attack"):
			if Input.is_action_pressed("move_back"):
				state_machine.transition_to(state_machine.get_node("UpperSlashState"))

	if Input.is_action_just_pressed("jump"):
		state_machine.transition_to(state_machine.get_node("JumpState"))
