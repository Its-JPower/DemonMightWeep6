class_name Boss
extends Enemy
signal weak_point_broken
@export var stagger_threshold: float = 100.0
@export_group("Attack")
@export var attack_time: float = 1.0
@export var recover_time: float = 0.8
@export var attack_damage: float = 20.0
@export var attack_range: float = 3.0
@export_group("Movement")
@export var move_speed: float = 3.5
@export var stop_distance: float = 2.0
@export var rotation_speed: float = 6.0
@export var gravity: float = 9.8
@export_group("Scoring")
@export var kill_points: int = 1000
var player: Node3D
var stagger_meter: float = 0.0
var is_staggered: bool = false
@onready var state_machine: BossStateMachine = $BossStateMachine
@onready var animation_player: AnimationPlayer = $Spider/AnimationPlayer
@onready var mesh: MeshInstance3D = $MeshInstance3D  # adjust path to your mesh node
const red_material: StandardMaterial3D = preload("uid://dc364wgj8xedm")
var original_material: Material = null
func _ready() -> void:
	super()
	player = get_tree().get_first_node_in_group("player")
	for wp in find_children("*", "WeakPoint", true, false):
		wp.hit.connect(_on_weak_point_hit)
	if mesh:
		original_material = mesh.get_surface_override_material(0)
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		knockback_velocity.y -= gravity * delta
		knockback_velocity.x = move_toward(knockback_velocity.x, 0.0, 40.0 * delta)
		knockback_velocity.z = move_toward(knockback_velocity.z, 0.0, 40.0 * delta)
	else:
		knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 40.0 * delta)
		if velocity.y < 0.0:
			velocity.y = 0.0
	velocity.y = knockback_velocity.y
	move_and_slide()
func _on_weak_point_hit(damage: float) -> void:
	take_damage(damage)
	stagger_meter += damage
	if stagger_meter >= stagger_threshold and not is_staggered:
		_trigger_stagger()
	weak_point_broken.emit()
func _trigger_stagger() -> void:
	is_staggered = true
	stagger_meter = 0.0
	state_machine.transition_to("Staggered")
func recover_from_stagger() -> void:
	is_staggered = false
func _on_died() -> void:
	Score.register_kill(kill_points)
	if player and player.has_method("heal_on_kill"):
		player.heal_on_kill()
	died.emit()
	state_machine.transition_to("Death")
	# no queue_free() — DeathState owns cleanup/removal timing
# 1.0 at full health -> 1.6 at low health
func get_aggression_scale() -> float:
	return lerp(1.6, 1.0, health / max_health)
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
	var dir = (player.global_position - global_position)
	dir.y = 0.0
	if dir.length() > 0.01:
		dir = dir.normalized()
		velocity.x = dir.x * move_speed + knockback_velocity.x
		velocity.z = dir.z * move_speed + knockback_velocity.z
	else:
		velocity.x = knockback_velocity.x
		velocity.z = knockback_velocity.z
	face_player(delta)
func _on_damaged(_amount: float) -> void:
	_flash_red()
func _flash_red() -> void:
	if not mesh:
		return
	mesh.set_surface_override_material(0, red_material)
	await get_tree().create_timer(0.15).timeout
	mesh.set_surface_override_material(0, original_material)
