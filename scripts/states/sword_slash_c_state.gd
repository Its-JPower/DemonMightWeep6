class_name SwordSlashCState
extends State
@onready var sword: Sword = $"../../Mesh/Skeleton3D/BoneAttachment3D/Sword"
var timer := 0.0
var has_hit := false
var duration := 0.6
var attack_buffered := false
var special_buffered := false
var state_name := "SwordSlashCState"
const BUFFER_OPEN := 0.45
const HIT1_START := 0.0
const HIT1_END := 0.2
const HIT2_START := 0.3
const HIT2_END := 0.5
var hitbox_phase := 0

func enter() -> void:
	player.velocity.x = 0.0
	player.velocity.z = 0.0
	player._lock_on_idle_timer = 0.0
	player.anim_player.play("Sword_Regular_C", -1, 1.0)
	var anim = player.anim_player.get_animation("Sword_Regular_C")
	duration = anim.length if anim else 0.6
	timer = 0.0
	attack_buffered = false
	special_buffered = false
	hitbox_phase = 0
	state_machine.combo_index = 0
	state_machine.combo_timer = 0.0
	if not sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.connect(_on_hit)
	sword.enable_hitbox()

func physics_process(delta: float) -> void:
	var dir = player.get_movement_input()
	timer += delta
	if timer < duration * 0.3:
		var forward = -player.player_model.global_transform.basis.z
		player.velocity.x = move_toward(player.velocity.x, forward.x * 1.5, 20.0 * delta)
		player.velocity.z = move_toward(player.velocity.z, forward.z * 1.5, 20.0 * delta)
	else:
		player.apply_movement(delta)
	player.apply_gravity(delta)
	_update_hitbox_windows()

	if timer >= duration * BUFFER_OPEN:
		if Input.is_action_pressed("special"):
			if Input.is_action_just_pressed("attack"):
				var forward = -player.player_model.global_transform.basis.z
				if dir.dot(forward) > 0.5:
					state_machine.transition_to(state_machine.get_node("AbdomenPiercerState"))
				elif dir.dot(-forward) > 0.5:
					state_machine.transition_to(state_machine.get_node("UpperSlashState"))
		elif Input.is_action_just_pressed("attack"):
			attack_buffered = true

	player.move_and_slide()
	if timer >= duration:
		if special_buffered:
			state_machine.combo_index = 0
			state_machine.combo_timer = 0.0
			state_machine.transition_to(state_machine.get_node("UpperSlashState"))
		elif attack_buffered:
			state_machine.combo_index = 0
			state_machine.combo_timer = 0.0
			state_machine.transition_to(state_machine.get_node("MillionStabsState"))
		else:
			_end_state()

func _update_hitbox_windows() -> void:
	var t := timer / duration
	match hitbox_phase:
		0:
			if t >= HIT1_END:
				sword.disable_hitbox()
				hitbox_phase = 1
		1:
			if t >= HIT2_START:
				sword.enable_hitbox()
				hitbox_phase = 2
		2:
			if t >= HIT2_END:
				sword.disable_hitbox()
				hitbox_phase = 3

func _on_hit(enemy: Enemy) -> void:
	if player.lock_on_target == null:
		player.set_lock_on_target(enemy)
	enemy.take_damage(PlayerStats.sword_slash_c_damage, Vector3.ZERO, 0.0)
	DamageNumbers.spawn(PlayerStats.sword_slash_c_damage, enemy.global_position)
	StyleRankManager.register_action(state_name, 10.0)

func exit() -> void:
	sword.disable_hitbox()
	if sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.disconnect(_on_hit)

func _end_state() -> void:
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
