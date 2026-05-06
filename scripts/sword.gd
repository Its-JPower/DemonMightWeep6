class_name Sword
extends Node3D

@onready var hitbox: Area3D = $SwordHitbox

var active := false
var has_hit := false

func _ready() -> void:
	hitbox.monitoring = false
	hitbox.body_entered.connect(_on_body_entered)

func enable_hitbox() -> void:
	has_hit = false
	hitbox.monitoring = true
	active = true

func disable_hitbox() -> void:
	hitbox.monitoring = false
	active = false

func _on_body_entered(body: Node3D) -> void:
	if not active or has_hit:
		return
	if body is Enemy:
		has_hit = true
		# Emit a signal upward — the state handles damage values
		hit_landed.emit(body)

signal hit_landed(enemy: Enemy)
