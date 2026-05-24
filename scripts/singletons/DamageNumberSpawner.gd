extends Node

const DamageNumber := preload("res://scenes/damage_number.tscn")


# Call this from anywhere a hit lands
# is_crit can be driven by whatever threshold makes sense for your game
func spawn(amount: float, world_position: Vector3, is_crit: bool = false) -> void:
	var popup := DamageNumber.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.global_position = world_position + Vector3(0, 1.2, 0)  # offset above origin
	popup.setup(amount, is_crit)
