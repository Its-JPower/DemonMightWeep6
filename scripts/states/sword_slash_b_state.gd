class_name SwordSlashBState
extends State

@onready var sword: Sword = $"../../Mesh/Skeleton3D/BoneAttachment3D/Sword"
var timer := 0.0
var has_hit := false
var duration := 0.6

func enter() -> void:
	player.anim_player.play("Sword_Regular_B")
	var anim = player.anim_player.get_animation("Sword_Regular_B")
	duration = anim.length if anim else 0.6
	timer = 0.0
	has_hit = false
	if not sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.connect(_on_hit)
	sword.enable_hitbox()

func physics_process(delta: float) -> void:
	timer += delta
	if timer >= duration * 0.5:
		sword.disable_hitbox()
	player.move_and_slide()
	if timer >= duration:
		_end_state()

func _on_hit(enemy: Enemy) -> void:
	if has_hit:
		return
	has_hit = true
	enemy.take_damage(
		PlayerStats.sword_slash_b_damage,
		Vector3.ZERO,
		0.0
	)

func _end_state():
	if player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("IdleState"))
	else:
		state_machine.transition_to(state_machine.get_node("FallState"))
