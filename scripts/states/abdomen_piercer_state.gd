class_name AbdomenPiercerState
extends State

var timer := 0.0
const DURATION := 0.6
const DASH_SPEED := 30.0
const VERTICAL_LOCK_TIME := 0.5  # how long to suppress gravity

var dash_direction := Vector3.ZERO

func enter() -> void:
	player.rotation_mode = Player.RotationMode.LOCKED
	timer = 0.0
	
	# Use model's current facing direction, not camera
	dash_direction = -player.player_model.global_transform.basis.z
	
	player.velocity.y = 0.0
	player.velocity = dash_direction * DASH_SPEED

func physics_process(delta: float) -> void:
	timer += delta
	
	var t = timer / DURATION  # 0.0 → 1.0 progress
	
	# Ease out the horizontal speed — punchy start, clean stop
	var speed = DASH_SPEED * (1.0 - ease(t, 0.4))
	player.velocity.x = dash_direction.x * speed
	player.velocity.z = dash_direction.z * speed
	
	# Suppress gravity for the first part so it reads as intentional
	if timer > VERTICAL_LOCK_TIME:
		player.apply_gravity(delta)
	else:
		player.velocity.y = 0.0
	
	player.move_and_slide()
	
	# Early exit if we slam into a wall
	if player.get_slide_collision_count() > 0:
		var collision = player.get_slide_collision(0)
		if abs(collision.get_normal().y) < 0.3:  # it's a wall, not a floor
			_end_state()
			return
	
	if timer >= DURATION:
		_end_state()

func _end_state() -> void:
	if player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("IdleState"))
	else:
		state_machine.transition_to(state_machine.get_node("FallState"))
