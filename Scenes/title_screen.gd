extends CanvasLayer

@onready var anim_player = $Donte_With_Animations.find_child("AnimationPlayer")

func _ready() -> void:
	if anim_player:
		await get_tree().process_frame
		anim_player.play("Stash 2/Idle")

func _process(delta: float) -> void:
	pass
