class_name BossRecoverState
extends BossState

func _init() -> void:
	state_name = "Recover"

var timer: float = 0.0

func enter() -> void:
	timer = 0.0

func physics_process(delta: float) -> void:
	timer += delta
	if timer >= state_machine.states["Attack"].current_attack.recover_time:
		state_machine.transition_to("Idle")
