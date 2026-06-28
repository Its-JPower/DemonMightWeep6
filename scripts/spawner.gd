class_name EnemySpawner
extends Node3D

signal enemy_spawned(enemy: Node3D)
signal cycle_completed(cycle_number: int)
signal spawner_finished()

@export_group("Enemies")
@export var enemy_scenes: Array[PackedScene] = []
@export var spawn_weights: Array[float] = []

@export_group("Cycle Settings")
@export var spawn_count: int = 3
@export var cycle_interval: float = 5.0
@export var spawn_stagger: float = 0.2
@export var wait_for_clearance: bool = false
@export var max_cycles: int = 0
@export var count_scale_per_cycle: float = 1.0
@export var interval_scale_per_cycle: float = 1.0

@export_group("Spawn Position")
@export var spawn_points: Array[Node3D] = []
@export var randomise_spawn_point: bool = true
@export var position_jitter: float = 0.0
@export var snap_to_ground: bool = true
@export_flags_3d_physics var ground_mask: int = 1
@export var raycast_height: float = 50.0

@export_group("Spawn Facing")
@export var face_target: Node3D = null
@export_range(0, 360) var random_rotation_range: float = 360.0

@export_group("Limits")
@export var max_live_enemies: int = 0
@export var spawn_parent: Node = null

@export_group("Debug")
## Enable to print spawn events, cycle progress, and state changes to the Output panel.
@export var debug: bool = false

var active: bool = false
var cycle_count: int = 0
var live_enemies: Array[Node3D] = []

var _cycle_timer: Timer
var _stagger_timer: Timer
var _current_interval: float
var _current_count: float
var _spawn_index: int = 0


func _ready() -> void:
	_cycle_timer = Timer.new()
	_cycle_timer.one_shot = true
	add_child(_cycle_timer)
	_cycle_timer.timeout.connect(_on_cycle_timer_timeout)
	_current_interval = cycle_interval
	_current_count = spawn_count


func start() -> void:
	if enemy_scenes.is_empty():
		push_error("EnemySpawner: no enemy_scenes assigned.")
		return
	active = true
	cycle_count = 0
	_current_interval = cycle_interval
	_current_count = spawn_count
	_log("Spawner started. max_cycles=%d  spawn_count=%d  wait_for_clearance=%s" % [
		max_cycles, spawn_count, wait_for_clearance])
	_run_cycle()


func stop() -> void:
	active = false
	_cycle_timer.stop()
	if _stagger_timer and not _stagger_timer.is_queued_for_deletion():
		_stagger_timer.stop()
	_log("Spawner stopped. live_enemies=%d" % live_enemies.size())


func pause() -> void:
	_cycle_timer.paused = true
	_log("Spawner paused.")


func resume() -> void:
	_cycle_timer.paused = false
	_log("Spawner resumed.")


func force_cycle() -> void:
	_cycle_timer.stop()
	_log("force_cycle() called.")
	_run_cycle()


func _run_cycle() -> void:
	if !active:
		return

	if wait_for_clearance and !live_enemies.is_empty():
		_log("Waiting for clearance — %d enemies still alive." % live_enemies.size())
		_cycle_timer.start(0.5)
		return

	cycle_count += 1
	_spawn_index = 0
	var to_spawn: int = int(_current_count)
	if max_live_enemies > 0:
		var available := max_live_enemies - live_enemies.size()
		if available < to_spawn:
			_log("Cycle %d: capped spawn count %d → %d (max_live_enemies limit)" % [
				cycle_count, to_spawn, available])
			to_spawn = mini(to_spawn, available)

	_log("=== Cycle %d start — spawning %d enemies (interval=%.2fs stagger=%.2fs) ===" % [
		cycle_count, to_spawn, _current_interval, spawn_stagger])

	if spawn_stagger > 0.0:
		_stagger_spawn(to_spawn)
	else:
		for i in to_spawn:
			_spawn_one()
		_finish_cycle()


func _stagger_spawn(count: int) -> void:
	if _spawn_index >= count:
		_finish_cycle()
		return
	_spawn_one()
	_spawn_index += 1
	_stagger_timer = Timer.new()
	_stagger_timer.one_shot = true
	add_child(_stagger_timer)
	_stagger_timer.timeout.connect(func():
		_stagger_timer.queue_free()
		_stagger_spawn(count))
	_stagger_timer.start(spawn_stagger)


func _spawn_one() -> void:
	var scene := _pick_scene()
	if scene == null:
		push_warning("EnemySpawner: _pick_scene() returned null.")
		return
	var enemy := scene.instantiate() as Node3D
	if enemy == null:
		push_error("EnemySpawner: scene root is not a Node3D.")
		return
	var parent: Node = spawn_parent if spawn_parent else get_parent()
	parent.add_child(enemy)
	var pos := _pick_position()
	enemy.global_position = pos
	_apply_rotation(enemy)
	live_enemies.append(enemy)
	enemy.tree_exiting.connect(_on_enemy_removed.bind(enemy))
	enemy_spawned.emit(enemy)
	_log("  Spawned '%s' at %s  (live=%d)" % [
		enemy.name, pos, live_enemies.size()])


func _finish_cycle() -> void:
	cycle_completed.emit(cycle_count)
	_log("Cycle %d complete. live_enemies=%d" % [cycle_count, live_enemies.size()])

	if max_cycles > 0 and cycle_count >= max_cycles:
		active = false
		spawner_finished.emit()
		_log("All %d cycles finished. Spawner done." % max_cycles)
		return

	_current_count = maxf(_current_count * count_scale_per_cycle, 1.0)
	_current_interval = maxf(_current_interval * interval_scale_per_cycle, 0.1)
	_log("Next cycle in %.2fs  (next_count=%d)" % [_current_interval, int(_current_count)])
	_cycle_timer.start(_current_interval)


func _apply_rotation(enemy: Node3D) -> void:
	if face_target:
		var dir := (face_target.global_position - enemy.global_position)
		dir.y = 0.0
		if dir.length_squared() > 0.001:
			enemy.look_at(enemy.global_position + dir, Vector3.UP)
	elif random_rotation_range > 0.0:
		var half := deg_to_rad(random_rotation_range * 0.5)
		enemy.rotation.y = randf_range(-half, half)


func _pick_position() -> Vector3:
	var base: Vector3
	if spawn_points.is_empty():
		base = global_position
	elif randomise_spawn_point:
		base = spawn_points.pick_random().global_position
	else:
		base = spawn_points[_spawn_index % spawn_points.size()].global_position

	if position_jitter > 0.0:
		var angle := randf_range(0.0, TAU)
		var radius := randf() * position_jitter
		base += Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)

	if snap_to_ground:
		base = _raycast_ground(base)

	return base


func _raycast_ground(pos: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		pos + Vector3.UP * raycast_height,
		pos + Vector3.DOWN * raycast_height,
		ground_mask
	)
	var result := space.intersect_ray(query)
	if result:
		return result["position"]
	push_warning("EnemySpawner: ground raycast missed at %s — using original position." % pos)
	return pos


func _pick_scene() -> PackedScene:
	if enemy_scenes.is_empty():
		return null
	if spawn_weights.size() != enemy_scenes.size():
		return enemy_scenes.pick_random()
	var total: float = 0.0
	for w in spawn_weights: total += w
	var roll := randf() * total
	var acc: float = 0.0
	for i in enemy_scenes.size():
		acc += spawn_weights[i]
		if roll <= acc:
			return enemy_scenes[i]
	return enemy_scenes.back()


func _on_enemy_removed(enemy: Node3D) -> void:
	live_enemies.erase(enemy)
	_log("Enemy '%s' removed. live_enemies=%d" % [enemy.name, live_enemies.size()])


func _on_cycle_timer_timeout() -> void:
	_run_cycle()


func _log(msg: String) -> void:
	if debug:
		print("[EnemySpawner] ", msg)
