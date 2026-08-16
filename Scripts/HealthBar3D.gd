class_name HealthBar3D
extends Node3D

@onready var fill: Sprite3D = $Fill

var full_width_px: float

func _ready() -> void:
	fill.region_enabled = true
	full_width_px = fill.texture.get_width()
	fill.region_rect = Rect2(0, 0, full_width_px, fill.texture.get_height())

func set_health(current: float, max_hp: float) -> void:
	var pct := clampf(current / max_hp, 0.0, 1.0)
	var r := fill.region_rect
	r.size.x = full_width_px * pct
	fill.region_rect = r
	fill.offset.x = -(full_width_px - r.size.x) * 0.5  # keep left edge fixed
