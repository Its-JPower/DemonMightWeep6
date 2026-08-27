class_name HurtState
extends State

var state_name: String = "HurtState"

@export var hurt_duration: float = 0.4
@export var hurt_animation: StringName = &"Hurt"
@export var idle_state: State

var timer: float = 0.0

func enter() -> void:
	timer = 0.0
	player.anim_player.play(hurt_animation)

func physics_process(delta: float) -> void:
	player.apply_gravity(delta)
	player.velocity.x = player.knockback_velocity.x
	player.velocity.z = player.knockback_velocity.z
	player.move_and_slide()
	timer += delta
	if timer >= hurt_duration:
		state_machine.transition_to(idle_state)
