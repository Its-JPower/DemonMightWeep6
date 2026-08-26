class_name Boss
extends CharacterBody3D

signal health_changed(current: float, max: float)
signal weak_point_broken
signal died

@export var max_health: float = 500.0
@export var stagger_threshold: float = 100.0

@export_group("Attack")
@export var telegraph_time: float = 1.0
@export var attack_time: float = 0.5
@export var recover_time: float = 0.8
@export var attack_damage: float = 20.0
@export var attack_range: float = 3.0

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

# 1.0 at full health -> 1.6 at low health
func get_aggression_scale() -> float:
	return lerp(1.6, 1.0, health / max_health)

@export_group("Movement")
@export var move_speed: float = 3.5
@export var stop_distance: float = 2.0
@export var rotation_speed: float = 6.0
@export var gravity: float = 9.8

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func face_player(delta: float) -> void:
	if player == null:
		return
	var dir = (player.global_position - global_position)
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	var target_rot = atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_rot, rotation_speed * delta)

func chase_player(delta: float) -> void:
	if player == null:
		return
	nav_agent.target_position = player.global_position
	if nav_agent.is_navigation_finished():
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var next_pos = nav_agent.get_next_path_position()
		var dir = (next_pos - global_position)
		dir.y = 0.0
		dir = dir.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
	face_player(delta)
	move_and_slide()
