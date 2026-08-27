extends Node
## Autoload singleton. Register this as "Score" in
## Project Settings > Autoload (path: res://score_manager.gd)

signal score_changed(new_score: int)
signal combo_changed(combo: int, multiplier: float)
signal run_ended(result: Dictionary)

@export var combo_window: float = 4.0          # seconds of no kills before combo resets
@export var combo_step: float = 0.1            # multiplier gained per combo stack
@export var combo_max_multiplier: float = 3.0
@export var damage_penalty_per_point: int = 5  # score lost per point of damage taken

var score: int = 0
var kills: int = 0
var damage_taken: float = 0.0
var combo: int = 0
var max_combo: int = 0

var _combo_timer: float = 0.0
var _run_start_msec: int = 0
var _run_active: bool = false

func _process(delta: float) -> void:
	if combo > 0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			combo = 0
			combo_changed.emit(combo, get_combo_multiplier())

## Call when a level/run begins.
func start_run() -> void:
	score = 0
	kills = 0
	damage_taken = 0.0
	combo = 0
	max_combo = 0
	_combo_timer = 0.0
	_run_start_msec = Time.get_ticks_msec()
	_run_active = true
	score_changed.emit(score)
	combo_changed.emit(combo, get_combo_multiplier())

## Call from an enemy's death handler. `points` is that enemy's base value.
func register_kill(points: int = 100) -> void:
	if not _run_active:
		return
	combo += 1
	max_combo = max(max_combo, combo)
	_combo_timer = combo_window
	kills += 1
	var gained := int(round(points * get_combo_multiplier()))
	score += gained
	score_changed.emit(score)
	combo_changed.emit(combo, get_combo_multiplier())

## Call from Player.take_damage() whenever damage actually lands.
func register_damage(amount: float) -> void:
	if not _run_active:
		return
	damage_taken += amount
	score = max(score - int(round(amount * damage_penalty_per_point)), 0)
	# Getting hit knocks the combo down a step instead of wiping it outright.
	combo = max(combo - 1, 0)
	_combo_timer = combo_window if combo > 0 else 0.0
	score_changed.emit(score)
	combo_changed.emit(combo, get_combo_multiplier())

func get_combo_multiplier() -> float:
	return min(1.0 + (combo * combo_step), combo_max_multiplier)

## Call on level complete / game over. Returns the summary dict to hand to Leaderboard.
func end_run() -> Dictionary:
	_run_active = false
	var duration := (Time.get_ticks_msec() - _run_start_msec) / 1000.0
	var result := {
		"score": score,
		"kills": kills,
		"max_combo": max_combo,
		"damage_taken": damage_taken,
		"duration": duration,
	}
	run_ended.emit(result)
	return result
