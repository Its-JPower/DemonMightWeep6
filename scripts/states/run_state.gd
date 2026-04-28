class_name RunState
extends State

func enter() -> void:
	pass
	#player.animation_player.play("run")

func physics_process(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_movement(delta)
	var dir = player.get_movement_input()
	player.move_and_slide()
	if Input.is_action_just_pressed("jump"):
		state_machine.transition_to(state_machine.get_node("JumpState"))
	elif dir.length() < 0.1:
		state_machine.transition_to(state_machine.get_node("IdleState"))
	elif not player.is_sprinting:
		state_machine.transition_to(state_machine.get_node("WalkState"))
