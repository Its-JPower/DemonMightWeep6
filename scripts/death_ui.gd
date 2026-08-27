extends CanvasLayer
## Attach anywhere under the Player (e.g. next to HealthBar in PlayerUI —
## it doesn't matter where in the tree, since a CanvasLayer always renders
## full-screen in its own layer regardless of its 3D parent). Listens for
## the player's run_summary_ready signal, shows the run's stats with an
## editable name field, and saves to the leaderboard when you head back
## to the main menu.

@export_file("*.tscn") var main_menu_scene_path: String = "res://scenes/title_screen.tscn"
@export var pause_game_on_death: bool = true
@export var layer_priority: int = 100   # higher = drawn above other CanvasLayers (e.g. your pause menu)
@export var default_name: String = "Player"

var _player: Node = null
var _stats_list: VBoxContainer
var _name_edit: LineEdit
var _last_result: Dictionary = {}
var _previous_mouse_mode: int = Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	layer = layer_priority
	process_mode = Node.PROCESS_MODE_ALWAYS   # so this + its controls work even while the tree is paused
	_build_layout()
	_find_player()

func _build_layout() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.visible = false
	add_child(root)
	set_meta("_root", root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 26)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "YOU DIED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	_stats_list = VBoxContainer.new()
	_stats_list.add_theme_constant_override("separation", 6)
	vbox.add_child(_stats_list)

	vbox.add_child(HSeparator.new())

	var name_label := Label.new()
	name_label.text = "Name for the leaderboard:"
	vbox.add_child(name_label)

	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = default_name
	_name_edit.max_length = 20
	_name_edit.text = default_name
	_name_edit.select_all_on_focus = true
	_name_edit.text_submitted.connect(func(_t): _on_main_menu_pressed())
	vbox.add_child(_name_edit)

	var menu_btn := Button.new()
	menu_btn.text = "Save & Return to Main Menu"
	menu_btn.custom_minimum_size = Vector2(0, 40)
	menu_btn.pressed.connect(_on_main_menu_pressed)
	vbox.add_child(menu_btn)

func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		# HUD can build before the player spawns — retry next frame.
		await get_tree().process_frame
		_find_player()
		return
	if _player.has_signal("run_summary_ready"):
		_player.run_summary_ready.connect(_on_run_summary_ready)

func _on_run_summary_ready(result: Dictionary) -> void:
	_last_result = result
	_populate_stats(result)

	var root: Control = get_meta("_root")
	root.visible = true

	_previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE   # release the camera's captured cursor so the UI is clickable

	if pause_game_on_death:
		get_tree().paused = true

	_name_edit.grab_focus()

func _populate_stats(result: Dictionary) -> void:
	for child in _stats_list.get_children():
		child.queue_free()

	var rank := Leaderboard.get_rank_of(int(result.get("score", 0)))
	var duration := float(result.get("duration", 0.0))
	var minutes := int(duration) / 60
	var seconds := int(duration) % 60

	_add_stat_row("Score", str(result.get("score", 0)))
	_add_stat_row("Kills", str(result.get("kills", 0)))
	_add_stat_row("Max Combo", str(result.get("max_combo", 0)))
	_add_stat_row("Damage Taken", str(int(round(result.get("damage_taken", 0.0)))))
	_add_stat_row("Run Time", "%d:%02d" % [minutes, seconds])
	_add_stat_row("Leaderboard Rank", "#%d" % rank)

func _add_stat_row(label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)

	_stats_list.add_child(row)

func _on_main_menu_pressed() -> void:
	var entered_name := _name_edit.text.strip_edges()
	Leaderboard.add_entry(entered_name if entered_name != "" else default_name, _last_result)

	if pause_game_on_death:
		get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	get_tree().change_scene_to_file(main_menu_scene_path)
