class_name Enemy
extends CharacterBody3D

@export var max_health := 40
@export var knockback_resistance := 1.0  # 1.0 = normal, 2.0 = half knockback
@export var health_bar: HealthBar3D
@export var spawn_grace_period: float = 0.75   # seconds after spawn before this enemy can attack
@export var hit_stun_duration: float = 0.5     # stun applied whenever this enemy takes damage

var health := max_health
var knockback_velocity := Vector3.ZERO
var stun_timer: Timer
var _ready_time_ms: int = 0

signal damaged(amount: float)
signal died
signal health_changed(current: float, max: float)

func _ready() -> void:
	health = max_health
	_ready_time_ms = Time.get_ticks_msec()
	stun_timer = Timer.new()
	stun_timer.one_shot = true
	stun_timer.wait_time = hit_stun_duration
	add_child(stun_timer)
	if health_bar:
		health_bar.set_health(health, max_health)
		health_changed.connect(health_bar.set_health)

func can_attack() -> bool:
	return Time.get_ticks_msec() - _ready_time_ms >= spawn_grace_period * 1000.0

func take_damage(amount: float, knockback: Vector3 = Vector3.ZERO, vertical_knockback: float = 0.0) -> void:
	health = max(health - amount, 0.0)
	knockback_velocity = knockback / knockback_resistance
	knockback_velocity.y = vertical_knockback / knockback_resistance
	stun_timer.start()
	emit_signal("damaged", amount)
	emit_signal("health_changed", health, max_health)
	_on_damaged(amount)
	if health <= 0:
		_on_died()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		knockback_velocity.y -= 9.8 * delta
		knockback_velocity.x = move_toward(knockback_velocity.x, 0.0, 40.0 * delta)
		knockback_velocity.z = move_toward(knockback_velocity.z, 0.0, 40.0 * delta)
	else:
		knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 40.0 * delta)
	velocity.x = knockback_velocity.x
	velocity.y = knockback_velocity.y
	velocity.z = knockback_velocity.z
	move_and_slide()

func _on_damaged(_amount: float) -> void:
	pass

func _on_died() -> void:
	emit_signal("died")
	queue_free()
