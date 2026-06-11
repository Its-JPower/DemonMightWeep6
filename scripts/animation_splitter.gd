@tool
extends EditorScript

func _run():
	var library = load("res://assets/animation resources/player_animations.res") as AnimationLibrary
	
	for anim_name in library.get_animation_list():
		var anim = library.get_animation(anim_name)
		var save_path = "res://assets/animation resources/%s.res" % anim_name
		ResourceSaver.save(anim, save_path)
		print("Saved: ", save_path)
