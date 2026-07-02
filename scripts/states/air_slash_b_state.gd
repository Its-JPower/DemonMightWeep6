class_name AirSlashBState
extends State

@onready var sword: Sword = $"../../Mesh/Skeleton3D/BoneAttachment3D/Sword"

const GRAVITY_STALL_DURATION := 0.15
const GRAVITY_SCALE_AFTER := 0.4
const HORIZONTAL_DRIFT := 0.5
const BUFFER_OPEN := 0.45

var timer := 0.0
var duration := 0.5
var has_hit := false
var attack_buffered := false

var state_name := "AirSlashBState"

func enter() -> void:
	player._lock_on_idle_timer = 0.0
	timer = 0.0
	has_hit = false
	attack_buffered = false
	player.anim_player.play("Sword_Regular_B", -1, 1.0)
	var anim = player.anim_player.get_animation("Sword_Regular_B")
	duration = anim.length if anim else 0.5
	player.velocity.y = 0.0
	var forward = -player.player_model.global_transform.basis.z
	player.velocity.x = forward.x * HORIZONTAL_DRIFT
	player.velocity.z = forward.z * HORIZONTAL_DRIFT
	if not sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.connect(_on_hit)
	sword.enable_hitbox()

func physics_process(delta: float) -> void:
	timer += delta

	if timer < GRAVITY_STALL_DURATION:
		player.velocity.y = 0.0
	else:
		player.velocity.y -= player.GRAVITY * GRAVITY_SCALE_AFTER * delta

	player.velocity.x = move_toward(player.velocity.x, 0.0, 4.0 * delta)
	player.velocity.z = move_toward(player.velocity.z, 0.0, 4.0 * delta)

	if timer >= duration * 0.5:
		sword.disable_hitbox()

	if timer >= duration * BUFFER_OPEN and Input.is_action_just_pressed("attack"):
		attack_buffered = true

	player.move_and_slide()

	if player.is_on_floor():
		_land()
		return

	if timer >= duration:
		if attack_buffered:
			state_machine.transition_to(state_machine.get_node("AirSlashCState"))
		else:
			state_machine.transition_to(state_machine.get_node("FallState"))

func _on_hit(enemy: Enemy) -> void:
	if player.lock_on_target == null:
		player.set_lock_on_target(enemy)
	enemy.take_damage(PlayerStats.sword_slash_b_damage, Vector3.ZERO, 0.0)
	DamageNumbers.spawn(PlayerStats.sword_slash_b_damage, enemy.global_position)
	StyleRankManager.register_action(state_name, 10.0)

func exit() -> void:
	sword.disable_hitbox()
	if sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.disconnect(_on_hit)

func _land() -> void:
	var dir = player.get_movement_input()
	if dir.length() > 0.1:
		state_machine.transition_to(
			state_machine.get_node("RunState") if player.is_sprinting
			else state_machine.get_node("WalkState"))
	else:
		state_machine.transition_to(state_machine.get_node("LandState"))
