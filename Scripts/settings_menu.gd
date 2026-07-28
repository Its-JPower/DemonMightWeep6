# SettingsMenu.gd
extends Control

@onready var tab_buttons: Array[Button] = [
	$MainLayout/TabList/AudioTab,
	$MainLayout/TabList/VideoTab,
	$MainLayout/TabList/ControlsTab,
]
@onready var panels: Array[Control] = [
	$MainLayout/Panels/AudioPanel,
	$MainLayout/Panels/VideoPanel,
	$MainLayout/Panels/ControlsPanel,
]
@onready var indicator: ColorRect = $MainLayout/TabList/Indicator

const ACTIVE_COLOR := Color.WHITE
const INACTIVE_COLOR := Color(0.45, 0.45, 0.48)

var current_tab: int = 0

func _ready() -> void:
	for i in tab_buttons.size():
		tab_buttons[i].pressed.connect(_on_tab_pressed.bind(i))
		tab_buttons[i].focus_mode = Control.FOCUS_ALL
	_select_tab(0, true)

func _on_tab_pressed(index: int) -> void:
	if index == current_tab:
		return
	_select_tab(index)

func _select_tab(index: int, instant: bool = false) -> void:
	current_tab = index

	for i in panels.size():
		panels[i].visible = (i == index)

	for i in tab_buttons.size():
		tab_buttons[i].add_theme_color_override(
			"font_color",
			ACTIVE_COLOR if i == index else INACTIVE_COLOR
		)

	_move_indicator(index, instant)

func _move_indicator(index: int, instant: bool) -> void:
	var target_y := tab_buttons[index].position.y
	if instant:
		indicator.position.y = target_y
		return

	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(indicator, "position:y", target_y, 0.22)
