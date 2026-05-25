extends Control

@onready var stateui: Label = $StateUI
@onready var state_machine: StateMachine = $"../../../../../StateMachine"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	stateui.text = str(state_machine.current_state) + "\n" + str($"../../../../..".velocity.y) + "\n" + str($"../../../../..".last_rotation_mode)
