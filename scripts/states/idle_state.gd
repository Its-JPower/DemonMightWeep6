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

	# Tick combo timeout
	if state_machine.combo_index > 0:
		state_machine.combo_timer += delta
		if state_machine.combo_timer >= state_machine.COMBO_TIMEOUT:
			state_machine.combo_index = 0
			state_machine.combo_timer = 0.0

	if not player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("JumpState"))
		return

	var dir = player.get_movement_input()
	if dir.length() > 0.1:
		if player.is_sprinting:
			state_machine.transition_to(state_machine.get_node("RunState"))
		else:
			state_machine.transition_to(state_machine.get_node("WalkState"))
		return

	if Input.is_action_just_pressed("attack"):
		var forward = -player.player_model.global_transform.basis.z
		if player.is_specialing_it:
			if dir.dot(forward) > 0.5:
				state_machine.transition_to(state_machine.get_node("AbdomenPiercerState"))
			elif dir.dot(-forward) > 0.5:
				state_machine.transition_to(state_machine.get_node("UpperSlashState"))
		else:
			state_machine.combo_timer = 0.0
			match state_machine.combo_index:
				0:
					state_machine.transition_to(state_machine.get_node("SwordSlashAState"))
				1:
					state_machine.transition_to(state_machine.get_node("SwordSlashBState"))
				2:
					state_machine.transition_to(state_machine.get_node("SwordSlashCState"))
				# A/B fast cycle — C resets back to A
				3:
					state_machine.combo_index = 0
					state_machine.transition_to(state_machine.get_node("SwordSlashAState"))

	if Input.is_action_just_pressed("jump"):
		state_machine.transition_to(state_machine.get_node("JumpState"))
