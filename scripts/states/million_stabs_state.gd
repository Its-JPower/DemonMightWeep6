class_name MillionStabsState
extends State

const STAB_COOLDOWN := 0.15
const INPUT_WINDOW := 0.3
const BASE_DAMAGE := 5.0
const MIN_DAMAGE := 1.0
const FALLOFF_RATE := 0.4
const STAB_LUNGE := 0.8          # tiny forward burst per stab

var stab_cooldown_timer := 0.0
var input_window_timer := 0.0
var current_damage := BASE_DAMAGE
var can_stab := false
var has_hit := false
var sword: Sword
var stab_direction := Vector3.ZERO

func enter() -> void:
	sword = player.get_node("Mesh/Skeleton3D/BoneAttachment3D/Sword")
	current_damage = BASE_DAMAGE
	stab_cooldown_timer = 0.0
	input_window_timer = INPUT_WINDOW
	can_stab = false
	has_hit = false
	# Lock facing toward target if locked on, otherwise use model forward
	stab_direction = -player.player_model.global_transform.basis.z
	player.velocity = Vector3.ZERO
	if not sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.connect(_on_hit)
	_do_stab()

func physics_process(delta: float) -> void:
	# Bleed off the lunge velocity
	player.velocity.x = move_toward(player.velocity.x, 0.0, 8.0 * delta)
	player.velocity.z = move_toward(player.velocity.z, 0.0, 8.0 * delta)
	player.apply_gravity(delta)
	player.move_and_slide()

	if stab_cooldown_timer > 0.0:
		stab_cooldown_timer -= delta

	if stab_cooldown_timer <= 0.0 and not can_stab:
		can_stab = true
		input_window_timer = INPUT_WINDOW

	if can_stab:
		input_window_timer -= delta
		if input_window_timer <= 0.0:
			_end_state()
			return

	if can_stab and Input.is_action_just_pressed("attack"):
		_do_stab()

func _do_stab() -> void:
	has_hit = false
	can_stab = false
	stab_cooldown_timer = STAB_COOLDOWN
	# Refresh direction in case player rotated (lock-on drift)
	stab_direction = -player.player_model.global_transform.basis.z
	# Tiny lunge per stab — makes rapid mashing feel kinetic
	player.velocity.x = stab_direction.x * STAB_LUNGE
	player.velocity.z = stab_direction.z * STAB_LUNGE
	sword.enable_hitbox()
	player.anim_player.play("Sword_Dash_RM", -1, 1.0)

func _on_hit(enemy: Enemy) -> void:
	if has_hit:
		return
	has_hit = true
	sword.disable_hitbox()
	enemy.take_damage(maxf(MIN_DAMAGE, current_damage), Vector3.ZERO, 0.0)
	current_damage = maxf(MIN_DAMAGE, current_damage - FALLOFF_RATE)

func exit() -> void:
	sword.disable_hitbox()
	if sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.disconnect(_on_hit)

func _end_state() -> void:
	if player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("IdleState"))
	else:
		state_machine.transition_to(state_machine.get_node("FallState"))
