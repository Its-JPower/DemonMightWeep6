class_name SwordSlashAState
extends State

@onready var sword: Sword = $"../../Mesh/Skeleton3D/BoneAttachment3D/Sword"
var timer := 0.0
var has_hit := false
var duration := 0.6
var attack_buffered := false

func enter() -> void:
	player.velocity.x = 0.0
	player.velocity.z = 0.0
	player._lock_on_idle_timer = 0.0  
	player.anim_player.play("Sword_Regular_A")
	var anim = player.anim_player.get_animation("Sword_Regular_A")
	duration = anim.length if anim else 0.6
	timer = 0.0
	has_hit = false
	attack_buffered = false
	state_machine.combo_index = 1  # we are at step 1
	state_machine.combo_timer = 0.0
	if not sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.connect(_on_hit)
	sword.enable_hitbox()

func physics_process(delta: float) -> void:
	timer += delta

	if timer >= duration * 0.5:
		sword.disable_hitbox()

	# Buffer window — second half of animation
	if timer >= duration * 0.5 and Input.is_action_just_pressed("attack"):
		attack_buffered = true

	player.move_and_slide()

	if timer >= duration:
		if attack_buffered:
			# Fast cycle: go straight to B
			state_machine.combo_timer = 0.0
			state_machine.transition_to(state_machine.get_node("SwordSlashBState"))
		else:
			_end_state()

func _on_hit(enemy: Enemy) -> void:
	print("_on_hit fired, enemy: ", enemy)
	if has_hit:
		print("already hit, returning")
		return
	has_hit = true
	player.set_lock_on_target(enemy)
	enemy.take_damage(PlayerStats.sword_slash_a_damage, Vector3.ZERO, 0.0)

func _end_state() -> void:
	player.anim_player.play("Sword_Regular_A_Rec")
	if player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("IdleState"))
	else:
		state_machine.transition_to(state_machine.get_node("FallState"))
