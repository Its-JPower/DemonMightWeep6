class_name BossStateMachine
extends Node

@export var initial_state: BossState

var current_state: BossState
var states: Dictionary = {}

@onready var boss: Boss = get_parent()

func _ready() -> void:
	for child in get_children():
		if child is BossState:
			states[child.state_name] = child
			child.boss = boss
			child.state_machine = self
	if initial_state:
		current_state = initial_state
		current_state.enter()

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_process(delta)

func transition_to(name: String) -> void:
	if not states.has(name):
		push_warning("BossStateMachine: no state '%s'" % name)
		return
	current_state.exit()
	current_state = states[name]
	current_state.enter()
