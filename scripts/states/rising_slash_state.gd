class_name RisingSlashState
extends State

@onready var sword: Sword = $"../../Mesh/Skeleton3D/BoneAttachment3D/Sword"

const RISE_VELOCITY := 9.0          # upward burst on entry
const RISE_GRAVITY_SCALE := 0.15    # almost no gravity on the way up
const FALL_GRAVITY_SCALE := 0.5     # gentle fall after peak
const PEAK_THRESHOLD := 0.5         # velocity.y below this = peaked
const HORIZONTAL_LOCK := 0.3        # seconds of horizontal lock at start

var timer := 0.0
var duration := 0.6
var has_peaked := false
var has_hit := false

var state_name := "RisingSlashState"

func enter() -> void:
	player._lock_on_idle_timer = 0.0
	timer = 0.0
	has_peaked = false
	has_hit = false
	player.anim_player.play("Sword_Rising_Slash", -1, 1.0)
	var anim = player.anim_player.get_animation("Sword_Rising_Slash")
	duration = anim.length if anim else 0.6
	# Burst upward
	player.velocity.y = RISE_VELOCITY
	# Lock horizontal briefly so it reads as a vertical move
	player.velocity.x = 0.0
	player.velocity.z = 0.0
	if not sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.connect(_on_hit)
	sword.enable_hitbox()

func physics_process(delta: float) -> void:
	timer += delta

	# Horizontal lock at start, then allow drift
	if timer > HORIZONTAL_LOCK:
		player.apply_movement(delta)

	# Gentle gravity on the way up, normal-ish on the way down
	if player.velocity.y > PEAK_THRESHOLD:
		player.velocity.y -= player.GRAVITY * RISE_GRAVITY_SCALE * delta
	else:
		has_peaked = true
		player.velocity.y -= player.GRAVITY * FALL_GRAVITY_SCALE * delta

	# Close hitbox at peak so it only hits on the upswing
	if has_peaked:
		sword.disable_hitbox()

	player.move_and_slide()

	if player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("LandState"))
		return

	if timer >= duration:
		state_machine.transition_to(state_machine.get_node("FallState"))

func _on_hit(enemy: Enemy) -> void:
	if has_hit:
		return
	has_hit = true
	player.set_lock_on_target(enemy)
	# Rising slash launches enemy upward — sets up air combo
	enemy.take_damage(
		PlayerStats.upper_slash_damage,
		Vector3.ZERO,
		PlayerStats.upper_slash_kb_vertical * 1.5)
	DamageNumbers.spawn(PlayerStats.upper_slash_damage, enemy.global_position)

func exit() -> void:
	sword.disable_hitbox()
	if sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.disconnect(_on_hit)
