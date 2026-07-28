# SettingsManager.gd (autoload as "Settings")
extends Node

const SAVE_PATH := "user://settings.cfg"

var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var fullscreen: bool = false
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

	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(window_size)

func _set_bus_volume(bus_name: String, linear_value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(max(linear_value, 0.0001)))
	AudioServer.set_bus_mute(idx, linear_value <= 0.0)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
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
	fullscreen = cfg.get_value("video", "fullscreen", false)
	window_size = cfg.get_value("video", "window_size", Vector2i(1920, 1080))
	mouse_sensitivity = cfg.get_value("controls", "mouse_sensitivity", 1.0)
	invert_y = cfg.get_value("controls", "invert_y", false)
