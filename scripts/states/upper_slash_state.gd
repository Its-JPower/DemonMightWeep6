class_name UpperSlashState
extends State

var timer := 0.0
const DURATION := 0.4
const HORIZONTAL_SPEED := 2.0
var lunge_direction := Vector3.ZERO
var has_hit := false

var hitbox: Area3D

func enter() -> void:
	if not hitbox:
		hitbox = player.get_node("UpperSlashHitbox")
	timer = 0.0
	has_hit = false
	lunge_direction = -player.player_model.global_transform.basis.z

	player.velocity.x = lunge_direction.x * HORIZONTAL_SPEED
	player.velocity.z = lunge_direction.z * HORIZONTAL_SPEED
	player.velocity.y = 0.0

	hitbox.monitoring = true   # activate on swing start

func physics_process(delta: float) -> void:
	timer += delta

	player.apply_gravity(delta)

	var t = timer / DURATION
	player.velocity.x = lunge_direction.x * HORIZONTAL_SPEED * (1.0 - t)
	player.velocity.z = lunge_direction.z * HORIZONTAL_SPEED * (1.0 - t)

	# Close the hit window halfway through
	if timer >= DURATION * 0.5:
		hitbox.monitoring = false

	player.move_and_slide()

	if timer >= DURATION:
		_end_state()

func _check_hit(area_or_body: Node3D) -> void:
	if has_hit:
		return
	if area_or_body is Enemy:
		var kb = lunge_direction * PlayerStats.upper_slash_kb_strength
		area_or_body.take_damage(
			PlayerStats.upper_slash_damage,
			kb,
			PlayerStats.upper_slash_kb_vertical
		)
		has_hit = true

func exit() -> void:
	hitbox.monitoring = false   # safety — always off when leaving state

func _end_state() -> void:
	if player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("IdleState"))
	else:
		state_machine.transition_to(state_machine.get_node("FallState"))
