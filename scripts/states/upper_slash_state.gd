class_name UpperSlashState
extends State

@onready var sword: Sword = $"../../Mesh/Skeleton3D/BoneAttachment3D/Sword"

var timer := 0.0
const DURATION := 0.4
const HORIZONTAL_SPEED := 2.0
var lunge_direction := Vector3.ZERO
var has_hit := false

func enter() -> void:
	player._lock_on_idle_timer = 0.0
	timer = 0.0
	has_hit = false  # reset so re-entry works
	lunge_direction = -player.player_model.global_transform.basis.z

	player.velocity.x = lunge_direction.x * HORIZONTAL_SPEED
	player.velocity.z = lunge_direction.z * HORIZONTAL_SPEED
	player.velocity.y = 0.0

	# Guard against double-connect
	if not sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.connect(_on_hit)

	sword.enable_hitbox()
	# trigger your animation here

func physics_process(delta: float) -> void:
	timer += delta
	player.apply_gravity(delta)

	var t := timer / DURATION
	player.velocity.x = lunge_direction.x * HORIZONTAL_SPEED * (1.0 - t)
	player.velocity.z = lunge_direction.z * HORIZONTAL_SPEED * (1.0 - t)

	# Close the hit window halfway through
	if timer >= DURATION * 0.5:
		sword.disable_hitbox()

	player.move_and_slide()

	if timer >= DURATION:
		_end_state()

func _on_hit(enemy: Enemy) -> void:
	if has_hit:
		return
	has_hit = true
	player.set_lock_on_target(enemy)
	var kb := lunge_direction * PlayerStats.upper_slash_kb_strength
	enemy.take_damage(
		PlayerStats.upper_slash_damage,
		kb,
		PlayerStats.upper_slash_kb_vertical
	)

func exit() -> void:
	sword.disable_hitbox()
	if sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.disconnect(_on_hit)

func _end_state() -> void:
	if player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("IdleState"))
	else:
		state_machine.transition_to(state_machine.get_node("FallState"))
