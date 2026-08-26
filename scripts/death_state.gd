class_name DeathState
extends State

@export var death_animation: StringName = &"Death"

func enter() -> void:
	player.anim_player.play(death_animation)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func physics_process(delta: float) -> void:
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.DECELERATION * delta)
	player.velocity.z = move_toward(player.velocity.z, 0.0, player.DECELERATION * delta)
	player.move_and_slide()
