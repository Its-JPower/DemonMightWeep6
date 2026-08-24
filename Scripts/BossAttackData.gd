class_name BossAttackData
extends Resource

@export var attack_name: String = "Attack"
@export var telegraph_time: float = 1.0
@export var attack_time: float = 0.5
@export var recover_time: float = 0.8
@export var min_range: float = 0.0
@export var max_range: float = 5.0
@export var cooldown: float = 4.0
@export var weight: float = 1.0
@export var damage: float = 20.0
@export var telegraph_scene: PackedScene

var last_used_time: float = -999.0
