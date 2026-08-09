class_name DownSlamState
extends State
@onready var sword: Sword = $"../../Mesh/Skeleton3D/BoneAttachment3D/Sword"
const SLAM_SPEED := 25.0
const SLAM_GRAVITY_MULTIPLIER := 3.0
const SLAM_DURATION_MAX := 2.0
const HIT_RADIUS := 1.5
# Anim time (seconds) where the charge/up-swing ends and the slam impact begins.
@export var CHARGE_ANIM_TIME := 1.0
# Anim time (seconds) of the impact segment played after landing.
@export var IMPACT_ANIM_TIME := 0.5
@export var MIN_SPEED_SCALE := 0.3
@export var MAX_SPEED_SCALE := 3.0
@export var IMPACT_SPEED_SCALE := 1.3
# Seek slightly ahead of CHARGE_ANIM_TIME on land to kill perceived input lag.
@export var LAND_SEEK_OFFSET := 0.08
var timer := 0.0
var has_landed := false
var hit_enemies := []
var state_name := "DownSlamState"

func enter() -> void:
	timer = 0.0
	has_landed = false
	hit_enemies.clear()
	player.velocity = Vector3.ZERO
	player.velocity.y = -SLAM_SPEED
	sword.enable_hitbox()
	if not sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.connect(_on_hit)

	player.anim_player.play("Down_Slam", -1, 1.0)
	player.anim_player.speed_scale = _compute_charge_speed_scale()

func _compute_charge_speed_scale() -> float:
	var space := player.get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.create(
		player.global_position,
		player.global_position + Vector3.DOWN * 100.0)
	params.collision_mask = 1
	var result := space.intersect_ray(params)
	if result.is_empty():
		return 1.0

	var dist: float = player.global_position.y - result.position.y
	var g = player.GRAVITY * SLAM_GRAVITY_MULTIPLIER
	var fall_time = (-SLAM_SPEED + sqrt(SLAM_SPEED * SLAM_SPEED + 2.0 * g * dist)) / g
	if fall_time <= 0.0:
		return 1.0

	return clamp(CHARGE_ANIM_TIME / fall_time, MIN_SPEED_SCALE, MAX_SPEED_SCALE)

func physics_process(delta: float) -> void:
	timer += delta
	if has_landed:
		return

	player.velocity.y -= player.GRAVITY * SLAM_GRAVITY_MULTIPLIER * delta
	player.move_and_slide()

	for i in player.get_slide_collision_count():
		var col = player.get_slide_collision(i)
		var collider = col.get_collider()
		if collider is Enemy and collider not in hit_enemies:
			hit_enemies.append(collider)
			collider.take_damage(
				PlayerStats.down_slam_damage,
				Vector3.ZERO,
				PlayerStats.down_slam_kb_vertical)

	if player.is_on_floor():
		has_landed = true
		player.anim_player.speed_scale = IMPACT_SPEED_SCALE
		player.anim_player.seek(CHARGE_ANIM_TIME + LAND_SEEK_OFFSET, true)
		sword.disable_hitbox()
		_on_land()
		return

	if timer >= SLAM_DURATION_MAX:
		_end_state()

func _on_land() -> void:
	
	player.camera_shake(6.7)
	var space := player.get_world_3d().direct_space_state
	var params := PhysicsShapeQueryParameters3D.new()
	var shape := SphereShape3D.new()
	shape.radius = HIT_RADIUS
	params.shape = shape
	params.transform = player.global_transform
	params.collision_mask = 1
	var results := space.intersect_shape(params)
	for result in results:
		var collider = result.collider
		if collider is Enemy and collider not in hit_enemies:
			hit_enemies.append(collider)
			var kb = (collider.global_position - player.global_position).normalized()
			kb.y = 0.0
			collider.take_damage(
				PlayerStats.down_slam_damage,
				kb * PlayerStats.down_slam_kb_strength,
				PlayerStats.down_slam_kb_vertical)
	player.anim_player.animation_finished.connect(_on_impact_anim_finished, CONNECT_ONE_SHOT)

func _on_hit(enemy: Enemy) -> void:
	if enemy not in hit_enemies:
		hit_enemies.append(enemy)
		enemy.take_damage(PlayerStats.down_slam_damage, Vector3.ZERO, PlayerStats.down_slam_kb_vertical)
		StyleRankManager.register_action(state_name, 10.0)

func _on_impact_anim_finished(_anim_name: String) -> void:
	_end_state()

func exit() -> void:
	sword.disable_hitbox()
	player.anim_player.speed_scale = 1.0
	if sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.disconnect(_on_hit)
	if player.anim_player.animation_finished.is_connected(_on_impact_anim_finished):
		player.anim_player.animation_finished.disconnect(_on_impact_anim_finished)

func _end_state() -> void:
	if player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("IdleState"))
	else:
		state_machine.transition_to(state_machine.get_node("FallState"))
