class_name WalkState
extends State

func enter() -> void:
	pass
#	player.animation_player.play("walk")


func physics_process(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_movement(delta)
	var dir = player.get_movement_input()
	player.move_and_slide()

	if dir.length() < 0.1:
		state_machine.transition_to(state_machine.get_node("IdleState"))
	elif player.is_sprinting:
		state_machine.transition_to(state_machine.get_node("RunState"))
	elif Input.is_action_just_pressed("jump"):
		state_machine.transition_to(state_machine.get_node("JumpState"))
	if Input.is_action_pressed("attack"):
		if player.velocity.length() > 0.1:
			state_machine.transition_to(state_machine.get_node("AbdomenPiercerState"))
