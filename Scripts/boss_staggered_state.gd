class_name BossStaggeredState
extends BossState

func _init() -> void:
	state_name = "Staggered"

@export var stagger_duration: float = 3.0
var timer: float = 0.0

func enter() -> void:
	timer = 0.0

func physics_process(delta: float) -> void:
	timer += delta
	if timer >= stagger_duration:
		boss.recover_from_stagger()
		state_machine.transition_to("Idle")
