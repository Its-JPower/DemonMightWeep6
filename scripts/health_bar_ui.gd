extends Control
## Attach to a Control node in your HUD (a CanvasLayer in your gameplay
## scene, not the main menu). Builds its own bar in code and finds the
## Player automatically via the "player" group — no manual wiring needed
## beyond placing the node and positioning it in the editor (anchors/
## margins on this node control where the bar sits on screen).

@export var bar_size: Vector2 = Vector2(260, 24)
@export var bar_color: Color = Color(0.85, 0.15, 0.15)
@export var bg_color: Color = Color(0.15, 0.15, 0.15, 0.85)
@export var low_health_color: Color = Color(0.9, 0.75, 0.1)
@export var low_health_threshold: float = 0.3   # fraction of max health that triggers the color shift
@export var lerp_speed: float = 8.0             # how quickly the fill animates toward the real value
@export var show_text: bool = true

var _player: Node = null
var _target_fraction: float = 1.0
var _display_fraction: float = 1.0

var _fill: ColorRect
var _label: Label

func _ready() -> void:
	_build_layout()
	_find_player()

func _build_layout() -> void:
	custom_minimum_size = bar_size
	size = bar_size

	var bg := Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = bg_color
	bg_style.set_corner_radius_all(6)
	bg.add_theme_stylebox_override("panel", bg_style)
	add_child(bg)

	_fill = ColorRect.new()
	_fill.color = bar_color
	_fill.position = Vector2(3, 3)
	_fill.size = Vector2(bar_size.x - 6, bar_size.y - 6)
	add_child(_fill)

	if show_text:
		_label = Label.new()
		_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.add_theme_font_size_override("font_size", 14)
		_label.add_theme_color_override("font_color", Color.WHITE)
		_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		_label.add_theme_constant_override("shadow_offset_x", 1)
		_label.add_theme_constant_override("shadow_offset_y", 1)
		add_child(_label)

func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		# HUD can build before the player spawns — retry next frame.
		await get_tree().process_frame
		_find_player()
		return
	if _player.has_signal("health_changed"):
		_player.health_changed.connect(_on_health_changed)
	if "health" in _player and "max_health" in _player:
		_on_health_changed(_player.health, _player.max_health)

func _on_health_changed(current: float, max_health: float) -> void:
	_target_fraction = clamp(current / max_health, 0.0, 1.0) if max_health > 0 else 0.0
	_fill.color = low_health_color if _target_fraction <= low_health_threshold else bar_color
	if show_text and _label:
		_label.text = "%d / %d" % [int(round(current)), int(round(max_health))]

func _process(delta: float) -> void:
	if is_equal_approx(_display_fraction, _target_fraction):
		return
	_display_fraction = lerp(_display_fraction, _target_fraction, clamp(lerp_speed * delta, 0.0, 1.0))
	if absf(_display_fraction - _target_fraction) < 0.002:
		_display_fraction = _target_fraction
	_fill.size.x = (bar_size.x - 6) * _display_fraction
