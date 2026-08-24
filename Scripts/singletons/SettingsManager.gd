extends Node

const SAVE_PATH := "user://settings.cfg"

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

enum DisplayMode { FULLSCREEN, BORDERLESS, WINDOWED }

var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var display_mode: DisplayMode = DisplayMode.WINDOWED
var window_size: Vector2i = Vector2i(1920, 1080)
var mouse_sensitivity: float = 1.0
var invert_y: bool = false

func _ready() -> void:
	load_settings()
	apply_settings()

func apply_settings() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)
	_apply_display_mode()

func _apply_display_mode() -> void:
	match display_mode:
		DisplayMode.FULLSCREEN:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		DisplayMode.BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_size(window_size)
		DisplayMode.WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_size(window_size)

func _set_bus_volume(bus_name: String, linear_value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(max(linear_value, 0.0001)))
	AudioServer.set_bus_mute(idx, linear_value <= 0.0)

# --- Live setters ---

func set_master_volume(v: float) -> void:
	master_volume = v
	_set_bus_volume("Master", v)

func set_music_volume(v: float) -> void:
	music_volume = v
	_set_bus_volume("Music", v)

func set_sfx_volume(v: float) -> void:
	sfx_volume = v
	_set_bus_volume("SFX", v)

func set_display_mode(mode: DisplayMode) -> void:
	display_mode = mode
	_apply_display_mode()

func set_resolution_index(index: int) -> void:
	if index < 0 or index >= RESOLUTIONS.size():
		return
	window_size = RESOLUTIONS[index]
	if display_mode != DisplayMode.FULLSCREEN:
		DisplayServer.window_set_size(window_size)

func get_resolution_index() -> int:
	var idx := RESOLUTIONS.find(window_size)
	return idx if idx != -1 else RESOLUTIONS.find(Vector2i(1920, 1080))

func set_mouse_sensitivity(v: float) -> void:
	mouse_sensitivity = v

func set_invert_y(enabled: bool) -> void:
	invert_y = enabled

# --- Persistence ---

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("video", "display_mode", display_mode)
	cfg.set_value("video", "window_size", window_size)
	cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("controls", "invert_y", invert_y)
	cfg.save(SAVE_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	master_volume = cfg.get_value("audio", "master_volume", 1.0)
	music_volume = cfg.get_value("audio", "music_volume", 1.0)
	sfx_volume = cfg.get_value("audio", "sfx_volume", 1.0)
	display_mode = cfg.get_value("video", "display_mode", DisplayMode.WINDOWED) as DisplayMode
	window_size = cfg.get_value("video", "window_size", Vector2i(1920, 1080))
	mouse_sensitivity = cfg.get_value("controls", "mouse_sensitivity", 1.0)
	invert_y = cfg.get_value("controls", "invert_y", false)
