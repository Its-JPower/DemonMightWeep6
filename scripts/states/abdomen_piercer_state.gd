class_name AbdomenPiercerState
extends State

var timer := 0.0
const VERTICAL_LOCK_TIME := 0.5
const DASH_DURATION := 0.3
const DASH_SPEED := 20.0
var local_dash_speed: float
var local_duration: float
var dash_direction := Vector3.ZERO
var hit_enemies := []

var state_name := "AbdomenPiercerState"

func enter() -> void:
	player.anim_player.play("Sword_Dash_RM", -1, 1.0)
	hit_enemies.clear()
	local_dash_speed = DASH_SPEED + ((PlayerStats.ap_level - 1) * 5.0)
	local_duration = DASH_DURATION + ((PlayerStats.ap_level - 1) * 0.15)
	timer = 0.0
	dash_direction = -player.player_model.global_transform.basis.z
	player.velocity = dash_direction * local_dash_speed
	player.velocity.y = 0.0

func physics_process(delta: float) -> void:
	timer += delta
	var t := clampf(timer / local_duration, 0.0, 1.0)
	var speed := local_dash_speed * (1.0 - ease(t, 0.4))
	player.velocity.x = dash_direction.x * speed
	player.velocity.z = dash_direction.z * speed

	if timer > VERTICAL_LOCK_TIME:
		player.apply_gravity(delta)
	else:
		player.velocity.y = 0.0

	player.move_and_slide()

	for i in player.get_slide_collision_count():
		var col = player.get_slide_collision(i)
		var collider = col.get_collider()
		if collider is Enemy and collider not in hit_enemies:
			hit_enemies.append(collider)
			collider.take_damage(
				PlayerStats.abdomen_piercer_damage,
				dash_direction * (PlayerStats.abdomen_piercer_kb_strength + (6.0 * (PlayerStats.ap_level - 1))),
				PlayerStats.abdomen_piercer_kb_vertical)
			StyleRankManager.register_action(state_name, 10.0)
			_end_state()
			return

	# Wall check — only bail on walls, not floors/ceilings
	for i in player.get_slide_collision_count():
		var col = player.get_slide_collision(i)
		if abs(col.get_normal().y) < 0.3:
			_end_state()
			return

	if timer >= local_duration:
		_end_state()

func _end_state() -> void:
	player.velocity.x *= 0.1
	player.velocity.z = 0.0
	if player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("IdleState"))
	else:
		state_machine.transition_to(state_machine.get_node("FallState"))
