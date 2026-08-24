class_name BossDeathState
extends BossState

func _init() -> void:
	state_name = "Death"

func enter() -> void:
	boss.set_physics_process(false)
	var col = boss.get_node_or_null("CollisionShape3D")
	if col:
		col.set_deferred("disabled", true)
