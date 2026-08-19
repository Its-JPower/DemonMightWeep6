class_name MeleeEnemy
extends Enemy

@export var move_speed := 3.5
@export var attack_damage := 15.0
@export var attack_range := 1.4          # metres — must be < detection_radius
@export var attack_cooldown := 1.2       # seconds between swings
@export var detection_radius := 10.0    # set CollisionShape3D radius to match

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var detection_area: Area3D = $DetectionArea
@onready var attack_timer: Timer = $AttackTimer
@onready var anim_player: AnimationPlayer = $AnimationPlayer  # optional

@onready var mesh: MeshInstance3D = $MeshInstance3D  # adjust path to your mesh node

const red_material: StandardMaterial3D = preload("uid://dc364wgj8xedm")
var original_material: Material = null
var stun_timer: Timer = null

var player: CharacterBody3D = null
var is_attacking := false

func _ready() -> void:
	super()                         # sets health = max_health

	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)

	nav_agent.path_desired_distance = 0.4
	nav_agent.target_desired_distance = attack_range * 0.9
	nav_agent.navigation_finished.connect(func(): print("nav finished"))
	nav_agent.path_changed.connect(func(): print("path updated, points: ", nav_agent.get_current_navigation_path().size()))
	if mesh:
		original_material = mesh.get_surface_override_material(0)
	mesh.set_surface_override_material(0, red_material)
	await get_tree().process_frame
	mesh.set_surface_override_material(0, original_material)
	stun_timer = Timer.new()
	stun_timer.one_shot = true
	stun_timer.wait_time = 0.5  # stun duration in seconds
	add_child(stun_timer)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		knockback_velocity.y -= 9.8 * delta
		knockback_velocity.x = move_toward(knockback_velocity.x, 0.0, 40.0 * delta)
		knockback_velocity.z = move_toward(knockback_velocity.z, 0.0, 40.0 * delta)
	else:
		knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 40.0 * delta)

	if player == null or not stun_timer.is_stopped():  # <- added stun check
		velocity = knockback_velocity
		move_and_slide()
		return

	var dist := global_position.distance_to(player.global_position)

	if dist <= attack_range:
		_try_attack()
		velocity = knockback_velocity
	else:
		is_attacking = false
		nav_agent.target_position = player.global_position
		var next_pos := nav_agent.get_next_path_position()
		var direction := (next_pos - global_position).normalized()
		velocity.x = direction.x * move_speed + knockback_velocity.x
		velocity.y = knockback_velocity.y
		velocity.z = direction.z * move_speed + knockback_velocity.z

		if Vector3(direction.x, 0, direction.z).length() > 0.01:
			var look_target := global_position + Vector3(direction.x, 0.0, direction.z)
			look_at(look_target, Vector3.UP)

	move_and_slide()

func _move_toward_player() -> void:
	nav_agent.target_position = player.global_position

	if nav_agent.is_navigation_finished():
		return

	var next_pos := nav_agent.get_next_path_position()
	var direction := (next_pos - global_position).normalized()

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

func _try_attack() -> void:
	if is_attacking or not attack_timer.is_stopped() or not stun_timer.is_stopped():
		return

	is_attacking = true
	velocity.x = 0.0
	velocity.z = 0.0

	if anim_player and anim_player.has_animation("attack"):
		anim_player.play("attack")

	# deal damage at the midpoint of the swing (adjust timing as needed)
	await get_tree().create_timer(attack_cooldown * 0.35).timeout
	_deal_damage()

	attack_timer.start()
	is_attacking = false

func _deal_damage() -> void:
	if player == null:
		return
	var dist := global_position.distance_to(player.global_position)
	if dist > attack_range * 1.2:   # small forgiveness window
		return

	if player.has_method("take_damage"):
		var knockback_dir := (player.global_position - global_position).normalized()
		player.take_damage(attack_damage, knockback_dir * 6.0, 3.0)

func _on_detection_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body

func _on_detection_body_exited(body: Node3D) -> void:
	if body == player:
		player = null

func _on_attack_timer_timeout() -> void:
	pass   # timer just tracks cooldown; logic is in _try_attack

func _on_damaged(amount: float) -> void:
	_flash_red()
	stun_timer.start()

func _flash_red() -> void:
	if not mesh:
		return
	mesh.set_surface_override_material(0, red_material)
	await get_tree().create_timer(0.15).timeout
	mesh.set_surface_override_material(0, original_material)

func _on_died() -> void:	
	#player.play_kill_sfx()
	# play death anim before queue_free, drop loot, etc.
	super()
