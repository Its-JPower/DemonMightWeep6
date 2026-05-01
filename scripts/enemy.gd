class_name Enemy
extends CharacterBody3D

@export var max_health := 100.0
@export var knockback_resistance := 1.0  # 1.0 = normal, 2.0 = half knockback

var health := max_health
var knockback_velocity := Vector3.ZERO

signal damaged(amount: float)
signal died

func _ready() -> void:
	health = max_health

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, vertical_knockback: float = 0.0) -> void:
	health -= amount
	knockback_velocity = knockback / knockback_resistance
	knockback_velocity.y = vertical_knockback / knockback_resistance  # overrides y entirely
	emit_signal("damaged", amount)
	_on_damaged(amount)
	if health <= 0:
		_on_died()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	# Bleed off knockback over time
	knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 18.0 * delta)
	velocity.x = knockback_velocity.x
	velocity.z = knockback_velocity.z

	move_and_slide()

func _on_damaged(_amount: float) -> void:
	pass

func _on_died() -> void:
	emit_signal("died")
	queue_free()
