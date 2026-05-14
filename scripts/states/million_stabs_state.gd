class_name MillionStabsState
extends State

const STAB_COOLDOWN := 0.15       # min time between stabs
const INPUT_WINDOW := 0.3         # how long player has to press again before state ends
const BASE_DAMAGE := 5.0
const MIN_DAMAGE := 1.0
const FALLOFF_RATE := 0.4         # damage lost per stab

var stab_cooldown_timer := 0.0
var input_window_timer := 0.0
var current_damage := BASE_DAMAGE
var can_stab := false             # true when cooldown has passed and waiting for input
var has_hit := false
var sword: Sword

func enter() -> void:
	sword = player.get_node("Mesh/Skeleton3D/BoneAttachment3D/Sword")
	current_damage = BASE_DAMAGE
	stab_cooldown_timer = 0.0
	input_window_timer = INPUT_WINDOW  # start countdown immediately
	can_stab = false
	has_hit = false

	player.velocity = Vector3.ZERO

	if not sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.connect(_on_hit)

	_do_stab()  # first stab fires immediately on entry

func physics_process(delta: float) -> void:
	# Lock player in place
	player.velocity = Vector3.ZERO
	player.move_and_slide()

	# Cooldown between stabs
	if stab_cooldown_timer > 0.0:
		stab_cooldown_timer -= delta

	# Once cooldown is done, open the input window
	if stab_cooldown_timer <= 0.0 and not can_stab:
		can_stab = true
		input_window_timer = INPUT_WINDOW

	# Count down input window while waiting for mash
	if can_stab:
		input_window_timer -= delta
		if input_window_timer <= 0.0:
			_end_state()  # player didn't press in time
			return

	# Accept input
	if can_stab and Input.is_action_just_pressed("attack"):
		_do_stab()

func _do_stab() -> void:
	has_hit = false
	can_stab = false
	stab_cooldown_timer = STAB_COOLDOWN
	sword.enable_hitbox()
	player.anim_player.play("Sword_Dash_RM")

func _on_hit(enemy: Enemy) -> void:
	if has_hit:
		return
	has_hit = true
	sword.disable_hitbox()

	var damage := maxf(MIN_DAMAGE, current_damage)
	enemy.take_damage(damage, Vector3.ZERO, 0.0)

	# Decay for next stab
	current_damage = maxf(MIN_DAMAGE, current_damage - FALLOFF_RATE)

func exit() -> void:
	sword.disable_hitbox()
	if sword.hit_landed.is_connected(_on_hit):
		sword.hit_landed.disconnect(_on_hit)

func _end_state() -> void:
	if player.is_on_floor():
		state_machine.transition_to(state_machine.get_node("IdleState"))
	else:
		state_machine.transition_to(state_machine.get_node("FallState"))
