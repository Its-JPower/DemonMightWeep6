class_name Sword
extends Node3D

@onready var hitbox: Area3D = $SwordHitbox
var active := false
var hit_enemies: Array[Enemy] = []

signal hit_landed(enemy: Enemy)

func _ready() -> void:
	hitbox.monitoring = false
	hitbox.body_entered.connect(_on_body_entered)

func enable_hitbox() -> void:
	hit_enemies.clear()
	hitbox.monitoring = true
	active = true

func disable_hitbox() -> void:
	hitbox.monitoring = false
	active = false

func _on_body_entered(body: Node3D) -> void:
	if not active:
		return
	if body is Enemy and body not in hit_enemies:
		hit_enemies.append(body)
		hit_landed.emit(body)
