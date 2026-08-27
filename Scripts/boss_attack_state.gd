class_name BossAttackState
extends BossState

var timer: float = 0.0
var hit_applied: bool = false
var clip_length: float = 1.0

func _init() -> void:
	state_name = "Attack"

func enter() -> void:
	timer = 0.0
	hit_applied = false
	boss.animation_player.play("Attack")
	var anim = boss.animation_player.get_animation("Attack")
	clip_length = anim.length if anim else 1.0

func physics_process(delta: float) -> void:
	boss.face_player(delta)
	timer += delta
	var scaled_time = timer * boss.get_aggression_scale()
	# damage lands at 60% through the clip — adjust to match the actual hit frame
	if not hit_applied and scaled_time >= clip_length * 0.6:
		_apply_damage()
		hit_applied = true
	if scaled_time >= clip_length + boss.recover_time:
		state_machine.transition_to("Idle")

func _apply_damage() -> void:
	if boss.player == null:
		return
	var dist = boss.global_position.distance_to(boss.player.global_position)
	if dist <= boss.attack_range and boss.player.has_method("take_damage"):
		var knockback_dir = (boss.player.global_position - boss.global_position).normalized()
		boss.player.take_damage(boss.attack_damage, knockback_dir, 6.0)
