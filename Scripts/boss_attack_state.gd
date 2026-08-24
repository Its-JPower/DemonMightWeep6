class_name BossAttackState
extends BossState

func _init() -> void:
	state_name = "Attack"

var current_attack: BossAttackData
var timer: float = 0.0
var hit_applied: bool = false

func enter() -> void:
	timer = 0.0
	hit_applied = false
	current_attack.last_used_time = Time.get_ticks_msec() / 1000.0

func physics_process(delta: float) -> void:
	timer += delta
	if not hit_applied and timer >= current_attack.attack_time * 0.5:
		_apply_damage()
		hit_applied = true
	if timer >= current_attack.attack_time:
		state_machine.transition_to("Recover")

func _apply_damage() -> void:
	if boss.player == null:
		return
	var dist = boss.global_position.distance_to(boss.player.global_position)
	if dist <= current_attack.max_range and boss.player.has_method("take_damage"):
		boss.player.take_damage(current_attack.damage)
