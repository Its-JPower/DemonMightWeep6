extends Node

signal rank_changed(new_rank: String)
signal points_changed(points: float)

enum Rank { D, C, B, A, S, SS, SSS }
const RANK_NAMES = ["D", "C", "B", "A", "S", "SS", "SSS"]
const RANK_THRESHOLDS = [0, 100, 250, 450, 700, 1000, 1400]

var style_points: float = 0.0
var current_rank: Rank = Rank.D

@export var decay_rate: float = 15.0  # points/sec drained when not attacking
@export var decay_grace_period: float = 1.5  # sec after last action before decay starts

var _time_since_last_action: float = 0.0

# Repetition tracking
var _recent_actions: Array[String] = []
const REPETITION_WINDOW: int = 6

func _process(delta: float) -> void:
	_time_since_last_action += delta
	if _time_since_last_action > decay_grace_period and style_points > 0:
		_add_points(-decay_rate * delta)

func register_action(action_name: String, base_value: float) -> void:
	_time_since_last_action = 0.0
	var multiplier := _get_repetition_multiplier(action_name)
	_add_points(base_value * multiplier)
	_track_action(action_name)

func register_damage_taken() -> void:
	_add_points(-style_points * 0.5)  # halve current points
	_recent_actions.clear()

func _get_repetition_multiplier(action_name: String) -> float:
	var count := _recent_actions.count(action_name)
	# each repeat in the recent window cuts value: 1.0, 0.6, 0.3, 0.1...
	match count:
		0: return 1.0
		1: return 0.6
		2: return 0.3
		_: return 0.1

func _track_action(action_name: String) -> void:
	_recent_actions.push_back(action_name)
	if _recent_actions.size() > REPETITION_WINDOW:
		_recent_actions.pop_front()

func _add_points(amount: float) -> void:
	style_points = clamp(style_points + amount, 0.0, RANK_THRESHOLDS[Rank.SSS])
	points_changed.emit(style_points)
	_update_rank()

func _update_rank() -> void:
	var new_rank := current_rank
	for i in range(RANK_THRESHOLDS.size() - 1, -1, -1):
		if style_points >= RANK_THRESHOLDS[i]:
			new_rank = i as Rank
			break
	if new_rank != current_rank:
		current_rank = new_rank
		rank_changed.emit(RANK_NAMES[current_rank])
