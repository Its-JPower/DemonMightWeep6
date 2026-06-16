# CombatHUD.gd
extends Control

@onready var state_machine: StateMachine = $"../../../../../StateMachine"
@onready var player = $"../../../../.."

# Move entry nodes
@onready var slash_a: TextureRect = $SlashA/TextureRect
@onready var slash_b: TextureRect = $SlashB/TextureRect
@onready var slash_c: TextureRect = $SlashC/TextureRect
@onready var upper_slash: TextureRect = $UpperSlash/TextureRect
@onready var rising_slash: TextureRect = $RisingSlash/TextureRect
@onready var air_slash_a: TextureRect = $AirSlashA/TextureRect
@onready var air_slash_b: TextureRect = $AirSlashB/TextureRect
@onready var air_slash_c: TextureRect = $AirSlashC/TextureRect
@onready var down_slam: TextureRect = $DownSlam/TextureRect
@onready var abdomen_piercer: TextureRect = $AbdomenPiercer/TextureRect
@onready var million_stabs: TextureRect = $MillionStabs/TextureRect
@onready var lock_on: TextureRect = $"Lock-On"/TextureRect
@onready var cam_lock: TextureRect = $CamLock/TextureRect

var all_icons: Array

func _ready() -> void:
	all_icons = [
		slash_a, slash_b, slash_c, upper_slash, rising_slash,
		air_slash_a, air_slash_b, air_slash_c, down_slam,
		abdomen_piercer, million_stabs, lock_on, cam_lock
	]

func _process(_delta: float) -> void:
	_update_hud()

func _update_hud() -> void:
	# Hide everything first
	for icon in all_icons:
		icon.hide()

	var state = state_machine.current_state
	var state_name = state.get_class() if state else ""
	var holding_special = Input.is_action_pressed("special")
	var on_floor = player.is_on_floor()

	# Lock-on and cam lock are always available
	lock_on.show()
	cam_lock.show()

	match state_name:
		"IdleState", "WalkState", "RunState", "LandState":
			slash_a.show()
			rising_slash.show()
			abdomen_piercer.show()

		"SwordSlashAState":
			slash_b.show()

		"SwordSlashBState":
			slash_c.show()

		"SwordSlashCState":
			million_stabs.show()

		"UpperSlashState":
			pass  # committed, nothing chainable

		"RisingSlashState":
			air_slash_a.show()

		"AirSlashAState":
			air_slash_b.show()

		"AirSlashBState":
			air_slash_c.show()

		"AirSlashCState":
			if holding_special:
				down_slam.show()
			else:
				air_slash_a.show()  # loop back

		"MillionStabsState":
			million_stabs.show()  # mash to continue

		"FallState":
			air_slash_a.show()
			abdomen_piercer.show()

		"AbdomenPiercerState":
			pass  # committed
