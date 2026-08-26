class_name HurtState
extends State

@export var hurt_duration: float = 0.4
@export var hurt_animation: StringName = &"Hurt"
var timer: float = 0.0

func enter() -> void:
	timer = 0.0
	player.anim_player.play(hurt_animation)

func physics_process(delta: float) -> void:
	player.apply_gravity(delta)
	player.velocity.x = move_toward(velocity.x, 0.0, player.DECELERATION * delta)
	player.velocity.z = move_toward(velocity.z, 0.0, player.DECELERATION * delta)
	player.move_and_slide()
	timer += delta
	if timer >= hurt_duration:
		state_machine.transition_to("IdleState")
