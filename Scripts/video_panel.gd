extends VBoxContainer

@onready var display_mode_option: OptionButton = $DisplayModeOption
@onready var resolution_option: OptionButton = $ResolutionOption

func _ready() -> void:
	display_mode_option.clear()
	display_mode_option.add_item("Fullscreen")
	display_mode_option.add_item("Borderless")
	display_mode_option.add_item("Windowed")
	display_mode_option.selected = Settings.display_mode

	resolution_option.selected = Settings.get_resolution_index()
	resolution_option.disabled = Settings.display_mode == Settings.DisplayMode.FULLSCREEN

	display_mode_option.item_selected.connect(_on_display_mode_selected)
	resolution_option.item_selected.connect(_on_resolution_selected)

func _on_display_mode_selected(index: int) -> void:
	var mode := index as Settings.DisplayMode
	Settings.set_display_mode(mode)
	resolution_option.disabled = mode == Settings.DisplayMode.FULLSCREEN
	Settings.save_settings()

func _on_resolution_selected(index: int) -> void:
	Settings.set_resolution_index(index)
	Settings.save_settings()
