class_name StateMachine
extends Node

@export var initial_state: NodePath
var current_state: State

func init(player: CharacterBody3D) -> void:
	for child in get_children():
		child.player = player
		child.state_machine = self

	current_state = get_node(initial_state) as State
	if current_state == null:
		push_error("StateMachine: initial_state is null! Did you set it in the Inspector?")
		return
	current_state.enter()

func transition_to(new_state: State) -> void:
	if new_state == current_state:
		return
	current_state.exit()
	current_state = new_state
	current_state.enter()

func process(delta: float) -> void:
	current_state.process(delta)

func physics_process(delta: float) -> void:
	current_state.physics_process(delta)

func handle_input(event: InputEvent) -> void:
	current_state.handle_input(event)
