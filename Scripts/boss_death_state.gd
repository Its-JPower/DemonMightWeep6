class_name BossDeathState
extends BossState

@export var despawn_delay: float = 3.0  # time to linger after death anim before freeing

func _init() -> void:
	state_name = "Death"

func enter() -> void:
	boss.set_physics_process(false)
	boss.animation_player.play("Take_damage")
	await boss.get_tree().create_timer(0.3).timeout
	boss.animation_player.pause()
	var col = boss.get_node_or_null("CollisionShape3D")
	if col:
		col.set_deferred("disabled", true)
	await boss.get_tree().create_timer(despawn_delay).timeout
	boss.queue_free()
