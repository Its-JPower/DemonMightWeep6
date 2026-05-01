# dummy_enemy.gd
class_name DummyEnemy
extends Enemy

@export var respawn_time := 2.0
@onready var mesh: MeshInstance3D = $Mesh
@onready var hitbox: Area3D = $Hitbox

var origin_position: Vector3
var hit_tween: Tween

func _ready() -> void:
	super()
	origin_position = global_position
	hitbox.body_entered.connect(_on_body_entered)

# Flash red on hit
func _on_damaged(_amount: float) -> void:
	if hit_tween:
		hit_tween.kill()
	hit_tween = create_tween()
	var mat: StandardMaterial3D = mesh.get_surface_override_material(0)
	if mat:
		hit_tween.tween_property(mat, "albedo_color", Color.RED, 0.05)
		hit_tween.tween_property(mat, "albedo_color", Color.WHITE, 0.2)

# Respawn after death
func _on_died() -> void:
	emit_signal("died")
	mesh.visible = false
	await get_tree().create_timer(respawn_time).timeout
	health = max_health
	global_position = origin_position
	mesh.visible = true

# If the player body itself walks into the hitbox (optional melee trigger)
func _on_body_entered(body: Node3D) -> void:
	pass  # leave empty for now; damage is dealt by the attack state instead
