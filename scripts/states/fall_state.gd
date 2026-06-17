class_name FallState
extends State

const FALL_ANIM_DELAY := 0.15   # brief grace before fall anim plays (coyote feel)
var _fall_timer := 0.0

var state_name := "FallState"

func enter() -> void:
	_fall_timer = 0.0

func physics_process(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_movement(delta)
	player.move_and_slide()

	_fall_timer += delta

	# Small delay so hopping off a ledge doesn't snap to fall pose instantly
	if _fall_timer >= FALL_ANIM_DELAY:
		player.anim_player.play("Stash 2/Jump_Idle", -1, 1.0)

	if player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("LandState"))
		return

	if Input.is_action_just_pressed("attack"):
		if player.is_specialing_it:
			state_machine.transition_to(state_machine.get_node("DownSlamState"))
		else:
			state_machine.transition_to(state_machine.get_node("AirSlashAState"))
	if Input.is_action_just_pressed("jump") and player.is_specialing_it:
		state_machine.transition_to(state_machine.get_node("RisingSlashState"))
