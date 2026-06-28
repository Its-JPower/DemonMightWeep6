class_name UpperSlashState
extends State

@onready var sword: Sword = $"../../Mesh/Skeleton3D/BoneAttachment3D/Sword"
var timer := 0.0
const DURATION := 0.4
const HORIZONTAL_SPEED := 2.0
const LUNGE_FALLOFF := 2.5
var lunge_direction := Vector3.ZERO
var state_name := "UpperSlashState"

func enter() -> void:
	player._lock_on_idle_timer = 0.0
	timer = 0.0
	player.anim_player.play("Sword_Regular_A", -1, 1.0)
	lunge_direction = -player.player_model.global_transform.basis.z
	player.velocity.x = lunge_direction.x * HORIZONTAL_SPEED
	player.velocity.z = lunge_direction.z * HORIZONTAL_SPEED
	player.velocity.y = 0.0
	if not sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.connect(_on_hit)
	sword.enable_hitbox()

func physics_process(delta: float) -> void:
	timer += delta
	player.apply_gravity(delta)
	var current_speed := Vector2(player.velocity.x, player.velocity.z).length()
	var target_speed := maxf(0.0, current_speed - LUNGE_FALLOFF * delta)
	if current_speed > 0.001:
		var ratio := target_speed / current_speed
		player.velocity.x *= ratio
		player.velocity.z *= ratio
	if timer >= DURATION * 0.5:
		sword.disable_hitbox()
	player.move_and_slide()
	if timer >= DURATION:
		_end_state()

func _on_hit(enemy: Enemy) -> void:
	if player.lock_on_target == null:
		player.set_lock_on_target(enemy)
	var damage := PlayerStats.upper_slash_damage
	var is_crit = randf() < PlayerStats.crit_chance
	enemy.take_damage(
		damage,
		lunge_direction * PlayerStats.upper_slash_kb_strength,
		PlayerStats.upper_slash_kb_vertical)
	DamageNumbers.spawn(damage, enemy.global_position, is_crit)

func exit() -> void:
	sword.disable_hitbox()
	if sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.disconnect(_on_hit)

func _end_state() -> void:
	if player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("IdleState"))
	else:
		state_machine.transition_to(state_machine.get_node("FallState"))
