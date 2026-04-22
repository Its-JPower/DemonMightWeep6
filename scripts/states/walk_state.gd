class_name WalkState
extends State

func enter() -> void:
#	player.animation_player.play("walk")
	pass

func physics_process(delta: float) -> void:
	player.apply_gravity(delta)

	var dir = player.get_movement_input()
	player.velocity.x = dir.x * player.WALK_SPEED
	player.velocity.z = dir.z * player.WALK_SPEED

	# Rotate model to face movement direction
	if dir.length() > 0.1:
		var target_angle = atan2(dir.x, dir.z)
		player.rotation.y = lerp_angle(player.rotation.y, target_angle, player.ROTATION_SPEED * delta)

	player.move_and_slide()

	if dir.length() < 0.1:
		state_machine.transition_to(state_machine.get_node("IdleState"))
	elif Input.is_action_pressed("run"):
		state_machine.transition_to(state_machine.get_node("RunState"))
	elif Input.is_action_just_pressed("jump"):
		state_machine.transition_to(state_machine.get_node("JumpState"))
