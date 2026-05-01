class_name AbdomenPiercerState
extends State

var timer := 0.0
const VERTICAL_LOCK_TIME := 0.5  # how long to suppress gravity
const DASH_DURATION := 0.3
const DASH_SPEED := 20.0


var local_dash_speed
var local_duration
var dash_direction := Vector3.ZERO

func enter() -> void:
	local_dash_speed = DASH_SPEED + ((PlayerStats.ap_level-1)*5.0)
	local_duration = DASH_DURATION + ((PlayerStats.ap_level-1)*0.15)
	timer = 0.0
	
	# Use model's current facing direction, not camera
	dash_direction = -player.player_model.global_transform.basis.z
	
	player.velocity.y = 0.0
	player.velocity = dash_direction * local_dash_speed

func physics_process(delta: float) -> void:
	timer += delta
	
	var t = timer / local_duration  # 0.0 → 1.0 progress
	
	# Ease out the horizontal speed — punchy start, clean stop
	var speed = local_dash_speed * (1.0 - ease(t, 0.4))
	player.velocity.x = dash_direction.x * speed
	player.velocity.z = dash_direction.z * speed
	
	# Suppress gravity for the first part so it reads as intentional
	if timer > VERTICAL_LOCK_TIME:
		player.apply_gravity(delta)
	else:
		player.velocity.y = 0.0
	
	player.move_and_slide()
	for i in player.get_slide_collision_count():
		var col = player.get_slide_collision(i)
		var collider = col.get_collider()
		if collider is Enemy:
			# Dash knockback: strong forward push, slight upward launch
			
			var kb = dash_direction * 6.0*PlayerStats.ap_level
			collider.take_damage(
				PlayerStats.abdomen_piercer_damage,
				kb * PlayerStats.abdomen_piercer_kb_strength,
				PlayerStats.abdomen_piercer_kb_vertical)
			_end_state()
			return
	
	# Early exit if we slam into a wall
	if player.get_slide_collision_count() > 0:
		var collision = player.get_slide_collision(0)
		if abs(collision.get_normal().y) < 0.3:  # it's a wall, not a floor
			_end_state()
			return
	
	if timer >= local_duration:
		_end_state()

func _end_state() -> void:
	if player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("IdleState"))
	else:
		state_machine.transition_to(state_machine.get_node("FallState"))
