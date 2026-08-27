extends Control
## Attach to a Control node in your main menu (e.g. a full-screen Panel
## that starts hidden). Builds its own layout in code, so no extra scene
## setup is required. Call show_leaderboard() to populate + display it,
## hide_leaderboard() to close it back out.
@export var entry_font_size: int = 20
@export var header_font_size: int = 28
@export var column_widths: Array[int] = [40, 220, 100, 80, 110, 160]
var _list: VBoxContainer
func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build_layout()
func _build_layout() -> void:
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	var title := Label.new()
	title.text = "LEADERBOARD"
	title.add_theme_font_size_override("font_size", header_font_size)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var header := _make_row(["#", "Name", "Score", "Kills", "Max Combo", "Date"], true)
	vbox.add_child(header)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	var close_btn := Button.new()
	close_btn.text = "Back"
	close_btn.pressed.connect(hide_leaderboard)
	vbox.add_child(close_btn)
func _make_row(values: Array, is_header: bool = false) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	for i in values.size():
		var label := Label.new()
		label.text = str(values[i])
		label.custom_minimum_size.x = column_widths[i] if i < column_widths.size() else 100
		label.add_theme_font_size_override(
			"font_size", (header_font_size - 8) if is_header else entry_font_size)
		if is_header:
			label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		row.add_child(label)
	return row
## Call from your "Leaderboard" button.
func show_leaderboard() -> void:
	print("show_leaderboard called")
	_refresh()
	visible = true
## Call from the built-in Back button (already wired) or your own close logic.
func hide_leaderboard() -> void:
	visible = false
func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	var entries := Leaderboard.load_entries()
	print("Loaded entries: ", entries)
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No runs recorded yet — go get some kills."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(empty_label)
		return
	for i in entries.size():
		var e: Dictionary = entries[i]
		var date_str := ""
		if e.has("date"):
			date_str = str(e["date"]).split("T")[0]  # just the date part, drop time
		var row := _make_row([
			str(i + 1),
			e.get("name", "Player"),
			e.get("score", 0),
			e.get("kills", 0),
			e.get("max_combo", 0),
			date_str,
		])
		_list.add_child(row)
