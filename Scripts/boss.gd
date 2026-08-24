class_name Boss
extends CharacterBody3D

signal health_changed(current: float, max: float)
signal weak_point_broken
signal died

@export var max_health: float = 500.0
@export var attacks: Array[BossAttackData] = []
@export var min_attack_interval: float = 1.5
@export var stagger_threshold: float = 100.0

var health: float
var player: Node3D
var stagger_meter: float = 0.0
var is_staggered: bool = false

@onready var state_machine: BossStateMachine = $BossStateMachine

func _ready() -> void:
	health = max_health
	player = get_tree().get_first_node_in_group("player")
	for wp in find_children("*", "WeakPoint", true, false):
		wp.hit.connect(_on_weak_point_hit)

func take_damage(amount: float, is_weak_point: bool = false) -> void:
	health -= amount
	health_changed.emit(health, max_health)
	if is_weak_point:
		stagger_meter += amount
		if stagger_meter >= stagger_threshold and not is_staggered:
			_trigger_stagger()
	if health <= 0.0:
		die()

func _trigger_stagger() -> void:
	is_staggered = true
	stagger_meter = 0.0
	state_machine.transition_to("Staggered")

func recover_from_stagger() -> void:
	is_staggered = false

func die() -> void:
	died.emit()
	state_machine.transition_to("Death")

func _on_weak_point_hit(damage: float) -> void:
	take_damage(damage, true)
	weak_point_broken.emit()

# 1.0 at full health -> 1.6 at low health. Faster telegraphs, shorter cooldowns.
func get_aggression_scale() -> float:
	return lerp(1.6, 1.0, health / max_health)

func select_next_attack() -> BossAttackData:
	if player == null or attacks.is_empty():
		return null
	var dist = global_position.distance_to(player.global_position)
	var now = Time.get_ticks_msec() / 1000.0
	var candidates: Array[BossAttackData] = []
	for atk in attacks:
		var scaled_cooldown = atk.cooldown / get_aggression_scale()
		if dist >= atk.min_range and dist <= atk.max_range and (now - atk.last_used_time) >= scaled_cooldown:
			candidates.append(atk)
	if candidates.is_empty():
		return null
	var total_weight := 0.0
	for atk in candidates:
		total_weight += atk.weight
	var roll = randf() * total_weight
	for atk in candidates:
		roll -= atk.weight
		if roll <= 0.0:
			return atk
	return candidates.back()
