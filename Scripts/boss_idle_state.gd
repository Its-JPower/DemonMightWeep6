class_name BossIdleState
extends BossState

@export var min_wait: float = 1.0
var timer: float = 0.0

func _init() -> void:
	state_name = "Idle"

func enter() -> void:
	timer = 0.0

func physics_process(delta: float) -> void:
	if boss.player == null:
		return
	var dist = boss.global_position.distance_to(boss.player.global_position)
	if dist > boss.attack_range:
		boss.animation_player.play("Walk")
		boss.chase_player(delta)
		return
	boss.velocity.x = 0.0
	boss.velocity.z = 0.0
	boss.move_and_slide()
	boss.face_player(delta)
	boss.animation_player.play("Idle")
	timer += delta
	if timer >= min_wait / boss.get_aggression_scale():
		state_machine.transition_to("Attack")
