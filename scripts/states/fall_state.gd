class_name FallState
extends State

func enter() -> void:
	player.anim_player.play("NinjaJump_Idle")

func physics_process(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_movement(delta)
	player.move_and_slide()

	if player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("LandState"))
