extends Node3D

@onready var enemy_spawner: EnemySpawner = $Spawner

func _ready() -> void:
	enemy_spawner.start()
