# ControlsPanel.gd
extends VBoxContainer

@onready var sensitivity_slider: HSlider = $Sensitivity/SensitivitySlider
@onready var invert_y_check: CheckBox = $InvertY/InvertYCheck

func _ready() -> void:
	sensitivity_slider.min_value = 0.1
	sensitivity_slider.max_value = 3.0
	sensitivity_slider.step = 0.05

	sensitivity_slider.value = Settings.mouse_sensitivity
	invert_y_check.button_pressed = Settings.invert_y

	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	invert_y_check.toggled.connect(_on_invert_y_toggled)

func _on_sensitivity_changed(v: float) -> void:
	Settings.set_mouse_sensitivity(v)
	Settings.save_settings()

func _on_invert_y_toggled(enabled: bool) -> void:
	Settings.set_invert_y(enabled)
	Settings.save_settings()
