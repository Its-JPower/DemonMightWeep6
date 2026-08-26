class_name BossRecoverState
extends BossState

var timer: float = 0.0

func _init() -> void:
	state_name = "Recover"

func enter() -> void:
	timer = 0.0
	boss.animation_player.play("recover")

func physics_process(delta: float) -> void:
	timer += delta
	if timer >= boss.recover_time:
		state_machine.transition_to("Idle")
