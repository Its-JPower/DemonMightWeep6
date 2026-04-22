class_name JumpState
extends State

func enter() -> void:
	#player.animation_player.play("jump")
	player.velocity.y = player.JUMP_VELOCITY

func physics_process(delta: float) -> void:
	player.apply_gravity(delta)

	# Allow air control
	var dir = player.get_movement_input()
	player.velocity.x = dir.x * player.WALK_SPEED
	player.velocity.z = dir.z * player.WALK_SPEED

	player.move_and_slide()

	if player.is_on_floor():
		var dir2 = player.get_movement_input()
		if dir2.length() > 0.1:
			state_machine.transition_to(state_machine.get_node("WalkState"))
		else:
			state_machine.transition_to(state_machine.get_node("IdleState"))
