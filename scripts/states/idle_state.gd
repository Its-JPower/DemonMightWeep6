class_name IdleState
extends State

var state_name := "IdleState"

func enter() -> void:
	if state_machine.previous_state == AbdomenPiercerState:
		player.velocity = Vector3.ZERO
	player.anim_player.play("Stash 2/Idle", 1.0)
	# Bleed off lateral momentum smoothly instead of snapping to zero
	player.is_sprinting = false

func physics_process(delta: float) -> void:
	player.apply_gravity(delta)
	# Let deceleration handle the bleed-off rather than zeroing in enter()
	player.apply_movement(delta)
	player.move_and_slide()

	if state_machine.combo_index > 0:
		state_machine.combo_timer += delta
		if state_machine.combo_timer >= state_machine.COMBO_TIMEOUT:
			state_machine.combo_index = 0
			state_machine.combo_timer = 0.0

	if not player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("FallState"))
		return

	var dir = player.get_movement_input()
	if dir.length() > 0.1:
		state_machine.transition_to(
			state_machine.get_node("RunState") if player.is_sprinting
			else state_machine.get_node("WalkState"))
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
		# If no directional match while specialing, do nothing (intentional dead zone)
	else:
		state_machine.combo_timer = 0.0
		var next := ["SwordSlashAState", "SwordSlashBState", "SwordSlashCState", "SwordSlashAState"]
		state_machine.transition_to(state_machine.get_node(next[state_machine.combo_index]))
