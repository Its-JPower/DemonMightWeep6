class_name boss
extends Enemy
@export var move_speed := 3.5
@export var attack_damage := 15.0
@export var attack_range := 1.4          # metres
@export var attack_cooldown := 1.2       # seconds between swings
@export_group("Scoring")
@export var kill_points: int = 75
@onready var attack_timer: Timer = $AttackTimer
@onready var anim_player: AnimationPlayer = $Spider/AnimationPlayer
@onready var mesh: MeshInstance3D = $MeshInstance3D  # adjust path to your mesh node
const red_material: StandardMaterial3D = preload("uid://dc364wgj8xedm")
var original_material: Material = null
var player: CharacterBody3D = null
var is_attacking := false
func _ready() -> void:
	super()                         # sets health, spawn timer, stun_timer
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if mesh:
		original_material = mesh.get_surface_override_material(0)
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		knockback_velocity.y -= 9.8 * delta
		knockback_velocity.x = move_toward(knockback_velocity.x, 0.0, 40.0 * delta)
		knockback_velocity.z = move_toward(knockback_velocity.z, 0.0, 40.0 * delta)
	else:
		knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, 40.0 * delta)
	if player == null or not stun_timer.is_stopped():
		velocity = knockback_velocity
		move_and_slide()
		return
	var dist := global_position.distance_to(player.global_position)
	if dist > attack_range:
		is_attacking = false
		var direction := (player.global_position - global_position)
		direction.y = 0.0
		direction = direction.normalized()
		velocity.x = direction.x * move_speed + knockback_velocity.x
		velocity.y = knockback_velocity.y
		velocity.z = direction.z * move_speed + knockback_velocity.z
		if Vector3(direction.x, 0, direction.z).length() > 0.01:
			var look_target := global_position + Vector3(direction.x, 0.0, direction.z)
			look_at(look_target, Vector3.UP)
	elif can_attack():
		_try_attack()
		velocity = knockback_velocity
	else:
		# within range but still inside spawn grace period — hold, face player, don't attack
		velocity.x = knockback_velocity.x
		velocity.y = knockback_velocity.y
		velocity.z = knockback_velocity.z
		var look_dir := (player.global_position - global_position)
		look_dir.y = 0.0
		if look_dir.length() > 0.01:
			look_at(global_position + look_dir, Vector3.UP)
	move_and_slide()
	_update_locomotion_animation()
func _update_locomotion_animation() -> void:
	if is_attacking or not anim_player:
		return  # never interrupt the attack swing
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.1:
		if anim_player.has_animation("Walk") and anim_player.current_animation != "Walk":
			anim_player.play("Walk")
	else:
		if anim_player.has_animation("Idle") and anim_player.current_animation != "Idle":
			anim_player.play("Idle")
func _try_attack() -> void:
	if is_attacking or not attack_timer.is_stopped() or not stun_timer.is_stopped():
		return
	is_attacking = true
	velocity.x = 0.0
	velocity.z = 0.0
	if anim_player and anim_player.has_animation("Attack"):
		anim_player.play("Attack")
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
func _on_attack_timer_timeout() -> void:
	pass   # timer just tracks cooldown; logic is in _try_attack
func _on_damaged(amount: float) -> void:
	_flash_red()
func _flash_red() -> void:
	if not mesh:
		return
	mesh.set_surface_override_material(0, red_material)
	await get_tree().create_timer(0.15).timeout
	mesh.set_surface_override_material(0, original_material)
func _on_died() -> void:
	Score.register_kill(kill_points)
	if player and player.has_method("heal_on_kill"):
		player.heal_on_kill()
	#player.play_kill_sfx()
	# play death anim before queue_free, drop loot, etc.
	super()
