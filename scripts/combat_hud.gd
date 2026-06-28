# CombatHUD.gd
extends Control

@onready var state_machine: StateMachine = $"../../../../../../StateMachine"
@onready var player: Player = $"../../../../../.."

# Move entry nodes
@onready var special = $Special
@onready var slash_a = $SlashA
@onready var slash_b = $SlashB
@onready var slash_c = $SlashC
@onready var upper_slash = $UpperSlash
@onready var rising_slash = $RisingSlash
@onready var air_slash_a = $AirSlashA
@onready var air_slash_b = $AirSlashB
@onready var air_slash_c = $AirSlashC
@onready var down_slam = $DownSlam
@onready var abdomen_piercer = $AbdomenPiercer
@onready var million_stabs = $MillionStabs
@onready var lock_on = $"Lock-On"
@onready var cam_lock = $CamLock

var all_icons: Array

func _ready() -> void:
	all_icons = [
		special, slash_a, slash_b, slash_c, upper_slash, rising_slash,
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
	var state_name = state.state_name if state else ""
	var holding_special = Input.is_action_pressed("special")
	var on_floor = player.is_on_floor()
	# Lock-on and cam lock are always available
	lock_on.show()
	cam_lock.show()

	match state_name:
		"IdleState", "WalkState", "RunState", "LandState":
			if holding_special:
				rising_slash.show()
				abdomen_piercer.show()
			else:
				special.show()
				slash_a.show()

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
				special.show()
				air_slash_a.show()  # loop back

		"MillionStabsState":
			million_stabs.show()  # mash to continue

		"FallState":
			air_slash_a.show()
			if holding_special:
				down_slam.show()
		"JumpState":
			air_slash_a.show()
			if holding_special:
				down_slam.show()
			else:
				special.show()
				air_slash_a.show()

		"AbdomenPiercerState":
			pass  # committed
