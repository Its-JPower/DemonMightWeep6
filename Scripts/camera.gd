extends Camera3D

@export var target: NodePath
@export var distance: float = 5.0
@export var sensitivity: float = 0.005
@export var min_pitch: float = -0.4
@export var max_pitch: float = 1.2

var yaw: float = 0.0
var pitch: float = 0.5

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		yaw   -= event.relative.x * sensitivity
		pitch -= event.relative.y * sensitivity
		pitch  = clamp(pitch, min_pitch, max_pitch)

func _process(_delta):
	var t = get_node(target)
	if not t:
		return

	var offset = Vector3(0, 0, distance)
	offset = offset.rotated(Vector3.RIGHT, pitch)
	offset = offset.rotated(Vector3.UP, yaw)

	global_position = t.global_position + offset
	look_at(t.global_position, Vector3.UP)
