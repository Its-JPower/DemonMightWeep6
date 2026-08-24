class_name BossTelegraphState
extends BossState

func _init() -> void:
	state_name = "Telegraph"

var pending_attack: BossAttackData
var timer: float = 0.0
var telegraph_instance: Node3D

func enter() -> void:
	timer = 0.0
	if pending_attack.telegraph_scene:
		telegraph_instance = pending_attack.telegraph_scene.instantiate()
		boss.add_child(telegraph_instance)

func physics_process(delta: float) -> void:
	timer += delta
	if timer >= pending_attack.telegraph_time / boss.get_aggression_scale():
		state_machine.states["Attack"].current_attack = pending_attack
		state_machine.transition_to("Attack")

func exit() -> void:
	if telegraph_instance:
		telegraph_instance.queue_free()
		telegraph_instance = null
