extends CharacterBody3D

@export var max_speed: float = 10.0
@export var accel: float = 8.0
@export var drag: float = 2.0

@export var yaw_speed_deg: float = 120.0
@export var pitch_speed_deg: float = 90.0
@export var turn_smooth: float = 10.0

# If you want unlimited flips, leave this OFF.
@export var limit_pitch: bool = false
@export var pitch_limit_deg: float = 75.0   # only used if limit_pitch = true

@export var vertical_max_speed: float = 6.0
@export var vertical_accel: float = 10.0
@export var vertical_drag: float = 3.0

var yaw_in: float = 0.0
var pitch_in: float = 0.0

var yaw_deg: float = 0.0
var pitch_deg: float = 0.0

func _ready() -> void:
	yaw_deg = rotation_degrees.y
	pitch_deg = rotation_degrees.x
	rotation_degrees.z = 0.0

func _physics_process(delta: float) -> void:
	# Inputs
	var yaw_target: float = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	# UP = nose down, DOWN = nose up
	var pitch_target: float = float(Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_UP))
	var throttle: float = float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_S))
	var updown: float = float(Input.is_key_pressed(KEY_SPACE)) - float(Input.is_key_pressed(KEY_SHIFT))

	# Smooth inputs
	yaw_in = lerp(yaw_in, yaw_target, 1.0 - exp(-turn_smooth * delta))
	pitch_in = lerp(pitch_in, pitch_target, 1.0 - exp(-turn_smooth * delta))

	# Integrate yaw/pitch
	yaw_deg += yaw_speed_deg * yaw_in * delta
	pitch_deg += pitch_speed_deg * pitch_in * delta

	if limit_pitch:
		pitch_deg = clamp(pitch_deg, -pitch_limit_deg, pitch_limit_deg)
	else:
		# Wrap to keep the number from growing forever (optional but nice)
		pitch_deg = wrapf(pitch_deg, -180.0, 180.0)

	# Build basis from yaw then pitch (roll forced to 0)
	var yaw_rad: float = deg_to_rad(yaw_deg)
	var pitch_rad: float = deg_to_rad(pitch_deg)
	var b: Basis = Basis(Vector3.UP, yaw_rad) * Basis(Vector3.RIGHT, pitch_rad)

	var gt := global_transform
	gt.basis = b
	global_transform = gt

	# --- Movement ---
	# Full 3D forward movement (pitch affects travel direction)
	var forward: Vector3 = -global_transform.basis.z
	var desired_vel: Vector3 = forward * (throttle * max_speed)

	# Smooth toward desired forward velocity
	var a_move: float = accel if abs(throttle) > 0.001 else drag
	velocity = velocity.lerp(desired_vel, 1.0 - exp(-a_move * delta))

	# Independent vertical thrust (Space/Shift) in world-up
	var desired_v: float = updown * vertical_max_speed
	var a_v: float = vertical_accel if abs(updown) > 0.001 else vertical_drag
	velocity.y = lerp(velocity.y, desired_v, 1.0 - exp(-a_v * delta))

	move_and_slide()
