# AudioPanel.gd
extends VBoxContainer

@onready var master_slider: HSlider = $Master/MasterSlider
@onready var music_slider: HSlider = $Music/MusicSlider
@onready var sfx_slider: HSlider = $SFX/SFXSlider

func _ready() -> void:
	master_slider.min_value = 0.0
	master_slider.max_value = 1.0
	master_slider.step = 0.01
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.01
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.01

	master_slider.value = Settings.master_volume
	music_slider.value = Settings.music_volume
	sfx_slider.value = Settings.sfx_volume

	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

func _on_master_changed(v: float) -> void:
	Settings.set_master_volume(v)
	Settings.save_settings()

func _on_music_changed(v: float) -> void:
	Settings.set_music_volume(v)
	Settings.save_settings()

func _on_sfx_changed(v: float) -> void:
	Settings.set_sfx_volume(v)
	Settings.save_settings()
