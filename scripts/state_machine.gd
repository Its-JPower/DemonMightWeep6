class_name StateMachine
extends Node

@export var initial_state: NodePath
var current_state: State
var previous_state: State

func init(player: CharacterBody3D) -> void:
	for child in get_children():
		child.player = player
		child.state_machine = self
	current_state = get_node(initial_state) as State
	if current_state == null:
		push_error("StateMachine: initial_state is null! Did you set it in the Inspector?")
		return
	previous_state = null
	current_state.enter()

func transition_to(new_state: State) -> void:
	if new_state == current_state:
		return
	current_state.exit()
	previous_state = current_state
	current_state = new_state
	current_state.enter()

func physics_process(delta: float) -> void:
	if current_state == null:
		push_error("StateMachine: current_state is null!")
		return
	current_state.physics_process(delta)

func process(delta: float) -> void:
	current_state.process(delta)

func handle_input(event: InputEvent) -> void:
	if current_state == null:
		push_error("StateMachine: current_state is null!")
		return
	current_state.handle_input(event)
