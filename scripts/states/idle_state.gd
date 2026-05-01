class_name IdleState
extends State

func enter() -> void:
#	player.animation_player.play("idle")
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
			if Input.is_action_pressed("run"):
				state_machine.transition_to(state_machine.get_node("RunState"))
			else:
				state_machine.transition_to(state_machine.get_node("WalkState"))
	else:
		if Input.is_action_just_pressed("attack"):
			if Input.is_action_pressed("move_back"):
				state_machine.transition_to(state_machine.get_node("UpperSlashState"))

	if Input.is_action_just_pressed("jump"):
		state_machine.transition_to(state_machine.get_node("JumpState"))
