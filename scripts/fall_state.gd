class_name FallState
extends State

func enter() -> void:
	pass

func physics_process(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_movement(delta)
	player.move_and_slide()
	
	if player.is_on_floor():
		var direction = player.get_movement_input()
		if direction.length() > 0.1:
			state_machine.transition_to(state_machine.get_node("WalkState"))
		else:
			state_machine.transition_to(state_machine.get_node("IdleState"))
