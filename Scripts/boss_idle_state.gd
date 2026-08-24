class_name BossIdleState
extends BossState

func _init() -> void:
	state_name = "Idle"

var timer: float = 0.0

func enter() -> void:
	timer = 0.0

func physics_process(delta: float) -> void:
	timer += delta
	if timer < boss.min_attack_interval:
		return
	var attack = boss.select_next_attack()
	if attack:
		state_machine.states["Telegraph"].pending_attack = attack
		state_machine.transition_to("Telegraph")
