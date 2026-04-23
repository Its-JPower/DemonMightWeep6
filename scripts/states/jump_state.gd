class_name JumpState
extends State

var jumps_remaining := 0

func enter() -> void:
	#player.animation_player.play("jump")
	player.velocity.y = player.JUMP_VELOCITY
	jumps_remaining = 1

func handle_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("jump") and jumps_remaining > 0:
		player.velocity.y = player.JUMP_VELOCITY
		jumps_remaining -= 1

func physics_process(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_movement(delta)
	var dir = player.get_movement_input()
	player.move_and_slide()
	if player.is_on_floor():
		if dir.length() > 0.1:
			state_machine.transition_to(state_machine.get_node("WalkState"))
		else:
			state_machine.transition_to(state_machine.get_node("IdleState"))
