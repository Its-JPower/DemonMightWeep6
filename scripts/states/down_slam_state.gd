class_name DownSlamState
extends State

@onready var sword: Sword = $"../../Mesh/Skeleton3D/BoneAttachment3D/Sword"

const SLAM_SPEED := 25.0
const SLAM_GRAVITY_MULTIPLIER := 3.0
const SLAM_DURATION_MAX := 2.0
const HIT_RADIUS := 1.5
const STARTUP_FREEZE := 0.12    # brief airborne pause before dropping — classic slam feel

var timer := 0.0
var startup_timer := 0.0
var has_landed := false
var hit_enemies := []
var _in_startup := true

var state_name := "DownSlamState"

func enter() -> void:
	timer = 0.0
	startup_timer = 0.0
	has_landed = false
	_in_startup = true
	hit_enemies.clear()
	player.anim_player.play("Sword_Regular_A", -1, 1.0)
	# Freeze briefly mid-air for dramatic effect
	player.velocity = Vector3.ZERO
	sword.enable_hitbox()
	if not sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.connect(_on_hit)

func physics_process(delta: float) -> void:
	timer += delta

	if _in_startup:
		startup_timer += delta
		player.velocity = Vector3.ZERO   # hang in the air
		player.move_and_slide()
		if startup_timer >= STARTUP_FREEZE:
			_in_startup = false
			player.velocity.y = -SLAM_SPEED
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

	if player.is_on_floor() and not has_landed:
		has_landed = true
		sword.disable_hitbox()
		_on_land()
		return

	if timer >= SLAM_DURATION_MAX:
		_end_state()

func _on_land() -> void:
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
	if sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.disconnect(_on_hit)

func _end_state() -> void:
	if player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("IdleState"))
	else:
		state_machine.transition_to(state_machine.get_node("FallState"))
