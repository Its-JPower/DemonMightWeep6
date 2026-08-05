extends CanvasLayer

@onready var anim_player = $donte.find_child("AnimationPlayer")

func _ready() -> void:
	if anim_player:
		await get_tree().process_frame
		anim_player.play("Stash 2/Idle")

func _process(delta: float) -> void:
	pass

func _on_play_pressed():

	get_tree().change_scene_to_file("res://Scenes/test_map_scene.tscn")
