class_name EnemySpawner
extends Node3D

## Emitted each time a single enemy is spawned.
signal enemy_spawned(enemy: Node3D)
## Emitted after every enemy in a cycle has been spawned.
signal cycle_completed(cycle_number: int)
## Emitted when the spawner exhausts max_cycles (if capped).
signal spawner_finished()

@export_group("Enemies")
## Scenes to randomly pick from each spawn. Add multiple for variety.
@export var enemy_scenes: Array[PackedScene] = []
## Weighted chances matching enemy_scenes (leave empty = equal weight).
@export var spawn_weights: Array[float] = []

@export_group("Cycle Settings")
## How many enemies to spawn per cycle.
@export var spawn_count: int = 3
## Seconds between each cycle.
@export var cycle_interval: float = 5.0
## Seconds between individual spawns within a cycle (0 = all at once).
@export var spawn_stagger: float = 0.2
## Wait for all previous-cycle enemies to die before starting next cycle.
@export var wait_for_clearance: bool = false
## 0 = infinite cycles.
@export var max_cycles: int = 0
## Scale spawn_count by this each cycle (1.0 = constant).
@export var count_scale_per_cycle: float = 1.0
## Scale cycle_interval by this each cycle (e.g. 0.9 speeds up over time).
@export var interval_scale_per_cycle: float = 1.0

@export_group("Spawn Position")
## Spawn point nodes. If empty, spawner's own position is used.
@export var spawn_points: Array[Node3D] = []
## Randomise which spawn point is used each spawn.
@export var randomise_spawn_point: bool = true
## XZ radius of random position offset around chosen spawn point.
@export var position_jitter: float = 0.0
## Snap spawned enemy to the ground via raycast (requires physics layer set).
@export var snap_to_ground: bool = true
## Physics collision mask used for ground snapping raycast.
@export_flags_3d_physics var ground_mask: int = 1
## How high above the spawn point to start the ground raycast.
@export var raycast_height: float = 50.0

@export_group("Spawn Facing")
## Rotate spawned enemy to face a target node (e.g. the player).
@export var face_target: Node3D = null
## Random Y-axis rotation added on top (degrees). Ignored if face_target is set.
@export_range(0, 360) var random_rotation_range: float = 360.0

@export_group("Limits")
## Hard cap on live enemies from this spawner (0 = no cap).
@export var max_live_enemies: int = 0
## Node to reparent spawned enemies to (defaults to spawner's parent).
@export var spawn_parent: Node = null

## Runtime state ───────────────────────────────────────────
var active: bool = false
var cycle_count: int = 0
var live_enemies: Array[Node3D] = []

var _cycle_timer: Timer
var _current_interval: float
var _current_count: int
var _spawn_index: int = 0


func _ready() -> void:
	_cycle_timer = Timer.new()
	_cycle_timer.one_shot = true
	add_child(_cycle_timer)
	_cycle_timer.timeout.connect(_on_cycle_timer_timeout)
	_current_interval = cycle_interval
	_current_count = spawn_count


## ─── Public API ──────────────────────────────────────────

func start() -> void:
	if enemy_scenes.is_empty():
		push_error("EnemySpawner: no enemy_scenes assigned.")
		return
	active = true
	cycle_count = 0
	_current_interval = cycle_interval
	_current_count = spawn_count
	_run_cycle()


func stop() -> void:
	active = false
	_cycle_timer.stop()


func pause() -> void:
	_cycle_timer.paused = true


func resume() -> void:
	_cycle_timer.paused = false


func force_cycle() -> void:
	## Immediately trigger a cycle regardless of the timer.
	_cycle_timer.stop()
	_run_cycle()


## ─── Internal ────────────────────────────────────────────

func _run_cycle() -> void:
	if !active:
		return
	if wait_for_clearance and !live_enemies.is_empty():
		_cycle_timer.start(0.5)
		return

	cycle_count += 1
	_spawn_index = 0
	var to_spawn: int = int(_current_count)
	if max_live_enemies > 0:
		to_spawn = mini(to_spawn, max_live_enemies - live_enemies.size())

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
	var t := Timer.new()
	t.one_shot = true
	add_child(t)
	t.timeout.connect(func():
		t.queue_free()
		_stagger_spawn(count))
	t.start(spawn_stagger)


func _spawn_one() -> void:
	var scene := _pick_scene()
	if scene == null:
		return
	var enemy := scene.instantiate() as Node3D
	if enemy == null:
		push_error("EnemySpawner: scene root is not a Node3D.")
		return
	var parent: Node = spawn_parent if spawn_parent else get_parent()
	parent.add_child(enemy)
	enemy.global_position = _pick_position()
	_apply_rotation(enemy)
	live_enemies.append(enemy)
	enemy.tree_exiting.connect(_on_enemy_removed.bind(enemy))
	enemy_spawned.emit(enemy)


func _finish_cycle() -> void:
	cycle_completed.emit(cycle_count)
	if max_cycles > 0 and cycle_count >= max_cycles:
		active = false
		spawner_finished.emit()
		return
	_current_count = maxi(int(_current_count * count_scale_per_cycle), 1)
	_current_interval = maxf(_current_interval * interval_scale_per_cycle, 0.1)
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
	query.exclude = [self]
	var result := space.intersect_ray(query)
	if result:
		return result["position"]
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
func _on_cycle_timer_timeout() -> void:
	_run_cycle()
