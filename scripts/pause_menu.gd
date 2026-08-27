# on CanvasLayer (or wherever this script lives — adjust root as needed)
extends CanvasLayer
@onready var v_box: VBoxContainer = $VBoxContainer
@onready var settings_menu: Control = $SettingsMenu   # sibling under Camera3D
@onready var resume_button: Button = $VBoxContainer/ResumeBtn
@onready var settings_button: Button = $VBoxContainer/SettingsBtn
@onready var quit_button: Button = $VBoxContainer/QuitBtn
@onready var player: Player = $"../../../../.."
var settings_open: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	#settings_menu.visible = false
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	#if settings_menu.has_signal("back_pressed"):
		#settings_menu.back_pressed.connect(_close_settings)

func _unhandled_input(event: InputEvent) -> void:
	# If a blocking popup (e.g. the death/run-summary screen) is showing,
	# ignore pause input entirely.
	if get_tree().get_first_node_in_group("modal_ui"):
		return
	if event.is_action_pressed("pause"):
		if settings_open:
			_close_settings()
		elif visible:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()

func _pause() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	v_box.visible = true
	resume_button.grab_focus()

func _resume() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_pressed() -> void:
	_resume()

func _on_settings_pressed() -> void:
	settings_open = true
	v_box.visible = false
	settings_menu.visible = true

func _close_settings() -> void:
	Settings.save_settings()
	settings_open = false
	settings_menu.visible = false
	v_box.visible = true
	settings_button.grab_focus()

func _on_quit_pressed() -> void:
	if player:
		Leaderboard.add_entry("Player", player.finish_run())   # or show this same popup instead
	get_tree().change_scene_to_file("res://path/to/main_menu.tscn")
