extends Area3D

@onready var spawner: EnemySpawner = $"../Spawner"


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		spawner.start()
