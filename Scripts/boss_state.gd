class_name BossState
extends Node

var boss: Boss
var state_machine: BossStateMachine
var state_name: String = "BossState"

func enter() -> void: pass
func exit() -> void: pass
func physics_process(delta: float) -> void: pass
func handle_input(event: InputEvent) -> void: pass
