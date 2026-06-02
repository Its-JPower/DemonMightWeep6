# loading_screen.gd
extends Control

@onready var texture_progress_bar: TextureProgressBar = $CanvasLayer/CenterContainter/VBoxContainer/TextureProgressBar

var target_scene: String = "res://scenes/title_screen.tscn"  # default target

func _ready():
	ResourceLoader.load_threaded_request(target_scene)

func _process(_delta):
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(target_scene, progress)
	
	texture_progress_bar.value = progress[0] * 100
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var scene = ResourceLoader.load_threaded_get(target_scene)
		get_tree().change_scene_to_packed(scene)
		queue_free()
