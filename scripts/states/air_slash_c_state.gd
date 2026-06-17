class_name AirSlashCState
extends State

@onready var sword: Sword = $"../../Mesh/Skeleton3D/BoneAttachment3D/Sword"

# C has a longer stall and bigger knockback — feels like the finisher
const GRAVITY_STALL_DURATION := 0.2
const GRAVITY_SCALE_AFTER := 0.35
const HORIZONTAL_DRIFT := 0.8
const LAUNCH_KB := 6.0              # knocks enemy upward on hit
const BUFFER_OPEN := 0.45

var timer := 0.0
var duration := 0.55
var has_hit := false
var attack_buffered := false

var state_name := "AirSlashCState"

func enter() -> void:
	player._lock_on_idle_timer = 0.0
	timer = 0.0
	has_hit = false
	attack_buffered = false
	player.anim_player.play("Sword_Regular_C", -1, 1.0)
	var anim = player.anim_player.get_animation("Sword_Regular_C")
	duration = anim.length if anim else 0.55
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

	# C can chain into DownSlam if special is held
	if timer >= duration * BUFFER_OPEN and Input.is_action_just_pressed("attack"):
		attack_buffered = true

	player.move_and_slide()

	if player.is_on_floor():
		_land()
		return

	if timer >= duration:
		if attack_buffered and player.is_specialing_it:
			state_machine.transition_to(state_machine.get_node("DownSlamState"))
		elif attack_buffered:
			# Loop back to A for extended air combo
			state_machine.transition_to(state_machine.get_node("AirSlashAState"))
		else:
			state_machine.transition_to(state_machine.get_node("FallState"))

func _on_hit(enemy: Enemy) -> void:
	if has_hit:
		return
	has_hit = true
	player.set_lock_on_target(enemy)
	# C launches the enemy upward
	enemy.take_damage(PlayerStats.sword_slash_c_damage, Vector3.ZERO, LAUNCH_KB)
	DamageNumbers.spawn(PlayerStats.sword_slash_c_damage, enemy.global_position)

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
