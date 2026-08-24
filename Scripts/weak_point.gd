class_name WeakPoint
extends Area3D

signal hit(damage: float)

@export var damage_multiplier: float = 2.0
@export var exposed: bool = true
@export var flash_material: Material

var base_material: Material
@onready var mesh_instance: MeshInstance3D = get_node_or_null("MeshInstance3D")

func _ready() -> void:
	if mesh_instance:
		base_material = mesh_instance.get_surface_override_material(0)

func receive_hit(base_damage: float) -> void:
	if not exposed:
		return
	hit.emit(base_damage * damage_multiplier)
	_flash()

func _flash() -> void:
	if mesh_instance and flash_material:
		mesh_instance.set_surface_override_material(0, flash_material)
		await get_tree().create_timer(0.15).timeout
		mesh_instance.set_surface_override_material(0, base_material)
