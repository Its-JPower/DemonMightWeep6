class_name SwordSlashAState
extends State

@onready var sword: Sword = $"../../Mesh/Skeleton3D/BoneAttachment3D/Sword"

var timer := 0.0
var has_hit := false
var duration := 0.6
var attack_buffered := false

var state_name := "SwordSlashAState"

const BUFFER_OPEN := 0.45   # fraction of duration when buffer window opens

func enter() -> void:
	player.play_hit_sfx()
	player.velocity.x = 0.0
	player.velocity.z = 0.0
	player._lock_on_idle_timer = 0.0
	player.anim_player.play("Sword_Regular_A", -1, 1.0)
	var anim = player.anim_player.get_animation("Sword_Regular_A")
	duration = anim.length if anim else 0.6
	timer = 0.0
	attack_buffered = false
	state_machine.combo_index = 1
	state_machine.combo_timer = 0.0
	if not sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.connect(_on_hit)
	sword.enable_hitbox()

func physics_process(delta: float) -> void:
	timer += delta

	if timer < duration * 0.3:
		var forward = -player.player_model.global_transform.basis.z
		player.velocity.x = move_toward(player.velocity.x, forward.x * 1.5, 20.0 * delta)
		player.velocity.z = move_toward(player.velocity.z, forward.z * 1.5, 20.0 * delta)
	else:
		player.apply_movement(delta)

	player.apply_gravity(delta)

	if timer >= duration * 0.5:
		sword.disable_hitbox()

	if timer >= duration * BUFFER_OPEN and Input.is_action_just_pressed("attack"):
		attack_buffered = true

	player.move_and_slide()

	if timer >= duration:
		if attack_buffered:
			state_machine.combo_timer = 0.0
			state_machine.transition_to(state_machine.get_node("SwordSlashBState"))
		else:
			_end_state()

func _on_hit(enemy: Enemy) -> void:
	if player.lock_on_target == null:
		player.set_lock_on_target(enemy)
	var damage := PlayerStats.sword_slash_a_damage
	var is_crit = randf() < PlayerStats.crit_chance
	enemy.take_damage(damage, Vector3.ZERO, 0.0)
	DamageNumbers.spawn(damage, enemy.global_position, is_crit)
	StyleRankManager.register_action(state_name, 10.0)

func exit() -> void:
	sword.disable_hitbox()
	if sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.disconnect(_on_hit)

func _end_state() -> void:
	player.anim_player.play("Sword_Regular_A_Rec", -1, 1.0)
	var dir = player.get_movement_input()
	if dir.length() > 0.1:
		if player.is_sprinting:
			state_machine.transition_to(state_machine.get_node("RunState"))
		else:
			state_machine.transition_to(state_machine.get_node("WalkState"))
		return
	if player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("IdleState"))
	else:
		state_machine.transition_to(state_machine.get_node("FallState"))
