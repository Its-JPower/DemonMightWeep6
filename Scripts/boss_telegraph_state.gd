class_name BossTelegraphState
extends BossState

func _init() -> void:
	state_name = "Telegraph"

var timer: float = 0.0

func enter() -> void:
	timer = 0.0
	# play telegraph anim/VFX here

func physics_process(delta: float) -> void:
	timer += delta
	if timer >= boss.telegraph_time / boss.get_aggression_scale():
		state_machine.transition_to("Attack")
