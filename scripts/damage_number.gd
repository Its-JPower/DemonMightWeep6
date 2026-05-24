class_name DamageNumber
extends Node3D

@onready var label: Label3D = $Label3D

const NORMAL_COLOR := Color(1.0, 1.0, 1.0)
const CRIT_COLOR := Color(1.0, 0.85, 0.1)

const NORMAL_RISE_SPEED := 1.2
const NORMAL_DURATION := 0.9
const NORMAL_FONT_SIZE := 64

const CRIT_RISE_SPEED := 0.4
const CRIT_PUNCH_SCALE := 2.2
const CRIT_SETTLE_SCALE := 1.4
const CRIT_DURATION := 0.9
const CRIT_FONT_SIZE := 80

var _timer := 0.0
var _duration := 0.0
var _is_crit := false

func setup(amount: float, is_crit: bool) -> void:
	_is_crit = is_crit
	label.text = str(int(amount))

	if is_crit:
		label.modulate = CRIT_COLOR
		label.font_size = CRIT_FONT_SIZE
		label.outline_size = 8
		_duration = CRIT_DURATION
		scale = Vector3(CRIT_PUNCH_SCALE, CRIT_PUNCH_SCALE, CRIT_PUNCH_SCALE)
	else:
		label.modulate = NORMAL_COLOR
		label.font_size = NORMAL_FONT_SIZE
		label.outline_size = 5
		_duration = NORMAL_DURATION
		scale = Vector3.ONE

	# Slight random horizontal spread so stacked hits don't overlap
	position.x += randf_range(-0.3, 0.3)
	position.z += randf_range(-0.15, 0.15)

func _process(delta: float) -> void:
	_timer += delta
	var t := _timer / _duration  # 0.0 → 1.0

	if _is_crit:
		# Punch: scale down from PUNCH to SETTLE over first 30%, then hold
		if t < 0.3:
			var punch_t := t / 0.3
			var s := lerpf(CRIT_PUNCH_SCALE, CRIT_SETTLE_SCALE, ease(punch_t, 0.3))
			scale = Vector3(s, s, s)
		else:
			scale = Vector3(CRIT_SETTLE_SCALE, CRIT_SETTLE_SCALE, CRIT_SETTLE_SCALE)

		# Rise slowly then fade in last 30%
		position.y += CRIT_RISE_SPEED * delta
		if t > 0.7:
			var fade_t := (t - 0.7) / 0.3
			label.modulate.a = lerpf(1.0, 0.0, fade_t)
	else:
		# Float upward the whole time, fade in last 40%
		position.y += NORMAL_RISE_SPEED * delta
		if t > 0.6:
			var fade_t := (t - 0.6) / 0.4
			label.modulate.a = lerpf(1.0, 0.0, fade_t)

	if _timer >= _duration:
		queue_free()
