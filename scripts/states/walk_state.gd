class_name WalkState
extends State

func enter() -> void:
	player.anim_player.play("Stash 2/Walk", -1, 1.0)

func physics_process(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_movement(delta)
	player.move_and_slide()

	if not player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("FallState"))
		return

	var dir = player.get_movement_input()

	# Drive animation from state rather than re-playing every frame
	if player.is_sprinting:
		state_machine.transition_to(state_machine.get_node("RunState"))
		return

	if dir.length() < 0.1:
		state_machine.transition_to(state_machine.get_node("IdleState"))
		return

	if Input.is_action_just_pressed("jump"):
		state_machine.transition_to(state_machine.get_node("JumpState"))
		return

	if Input.is_action_just_pressed("attack"):
		_handle_attack(dir)

func _handle_attack(dir: Vector3) -> void:
	var forward = -player.player_model.global_transform.basis.z
	if player.is_specialing_it:
		if dir.dot(forward) > 0.5:
			state_machine.transition_to(state_machine.get_node("AbdomenPiercerState"))
		elif dir.dot(-forward) > 0.5:
			state_machine.transition_to(state_machine.get_node("UpperSlashState"))
	else:
		state_machine.combo_timer = 0.0
		var next := ["SwordSlashAState", "SwordSlashBState", "SwordSlashCState", "SwordSlashAState"]
		state_machine.transition_to(state_machine.get_node(next[state_machine.combo_index]))
