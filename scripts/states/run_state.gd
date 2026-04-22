class_name RunState
extends State

func enter() -> void:
	#player.animation_player.play("run")
	pass

func physics_process(delta: float) -> void:
	player.apply_gravity(delta)

	var dir = player.get_movement_input()
	player.velocity.x = dir.x * player.RUN_SPEED
	player.velocity.z = dir.z * player.RUN_SPEED

	player.move_and_slide()

	if dir.length() < 0.1:
		state_machine.transition_to(state_machine.get_node("IdleState"))
	elif not Input.is_action_pressed("run"):
		state_machine.transition_to(state_machine.get_node("WalkState"))
	elif Input.is_action_just_pressed("jump"):
		state_machine.transition_to(state_machine.get_node("JumpState"))
