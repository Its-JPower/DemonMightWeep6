class_name WalkState
extends State

func enter() -> void:
	player.anim_player.play("Stash 2/Walk", 1.0)

func physics_process(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_movement(delta)
	player.move_and_slide()

	if not player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("FallState"))
		return

	var dir = player.get_movement_input()

	if player.is_sprinting:
		player.anim_player.play("Stash 2/Sprint", 1.0)
	else:
		player.anim_player.play("Stash 2/Walk", 1.0)

	if dir.length() < 0.1:
		state_machine.transition_to(state_machine.get_node("IdleState"))
	elif player.is_sprinting:
		state_machine.transition_to(state_machine.get_node("RunState"))
	elif Input.is_action_just_pressed("jump"):
		state_machine.transition_to(state_machine.get_node("JumpState"))
	elif Input.is_action_pressed("attack"):
		var forward = -player.player_model.global_transform.basis.z
		if player.is_specialing_it:
			if dir.dot(forward) > 0.5:
				state_machine.transition_to(state_machine.get_node("AbdomenPiercerState"))
			elif dir.dot(-forward) > 0.5:
				state_machine.transition_to(state_machine.get_node("UpperSlashState"))
