class_name LandState
extends State

var _done: bool = false

func enter() -> void:
	_done = false
	player.anim_player.play("NinjaJump_Land")
	player.anim_player.animation_finished.connect(_on_anim_finished, CONNECT_ONE_SHOT)

func _on_anim_finished(_anim_name: String) -> void:
	_done = true

func physics_process(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_movement(delta)
	player.move_and_slide()

	var dir = player.get_movement_input()

	# Player can immediately walk/run out of the landing animation
	if dir.length() > 0.1:
		if player.is_sprinting:
			state_machine.transition_to(state_machine.get_node("RunState"))
		else:
			state_machine.transition_to(state_machine.get_node("WalkState"))
		return

	if Input.is_action_just_pressed("jump"):
		state_machine.transition_to(state_machine.get_node("JumpState"))
		return

	# Only go idle once the animation actually finishes
	if _done:
		state_machine.transition_to(state_machine.get_node("IdleState"))
