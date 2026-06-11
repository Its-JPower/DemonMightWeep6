extends CanvasLayer

@onready var anim_player = $donte.find_child("AnimationPlayer")

func _ready() -> void:
	if anim_player:
		await get_tree().process_frame
		anim_player.play("Stash 2/Idle")

func _process(delta: float) -> void:
	pass

func _on_play_pressed():
	# Load the loading screen scene
	var loading = load("res://scenes/loading_screen.tscn").instantiate()
	loading.target_scene = "res://scenes/test_map_scene.tscn"  # tell it where to go next
	
	get_tree().root.add_child(loading)
	get_tree().current_scene.queue_free()  # remove title screen
