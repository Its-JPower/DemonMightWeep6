extends CanvasLayer

func _ready():
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	if get_tree().paused:
		get_tree().paused = false
		hide()
	else:
		get_tree().paused = true
		show()
