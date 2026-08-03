# SettingsMenu.gd
extends Control

@onready var tab_bar: TabBar = $VBoxContainer/TabBar

@onready var panels: Array[Control] = [
	$VBoxContainer/Panels/AudioPanel,
	$VBoxContainer/Panels/VideoPanel,
	$VBoxContainer/Panels/ControlsPanel,
]
@onready var indicator: ColorRect = $VBoxContainer/TabBar/Indicator

const ACTIVE_COLOR := Color.WHITE
const INACTIVE_COLOR := Color(0.45, 0.45, 0.48)

var current_tab: int = 0

func _ready() -> void:

	tab_bar.tab_changed.connect(_on_tab_changed)
	call_deferred("_select_tab", 0, true)

	#back_button.pressed.connect(func(): 
		#Settings.save_settings()
		#back_pressed.emit()
	#)

func _on_tab_changed(index: int) -> void:
	if index == current_tab:
		return
	_select_tab(index)

func _select_tab(index: int, instant: bool = false) -> void:
	current_tab = index

	for i in panels.size():
		panels[i].visible = (i == index)

	_move_indicator(index, instant)

func _move_indicator(index: int, instant: bool) -> void:
	var tab_rect := tab_bar.get_tab_rect(index)
	var target_x := tab_rect.position.x
	var target_width := tab_rect.size.x

	if instant:
		indicator.position.x = target_x
		indicator.size.x = target_width
		return

	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(indicator, "position:x", target_x, 0.22)
	tween.tween_property(indicator, "size:x", target_width, 0.22)

# add to SettingsMenu.gd
#signal back_pressed
#@onready var back_button: Button = $BackButton  # wherever you place it in layout
