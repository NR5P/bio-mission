extends CharacterBody3D

@export var max_speed: float = 10.0
@export var accel: float = 8.0
@export var drag: float = 2.0

@export var yaw_speed_deg: float = 120.0
@export var pitch_speed_deg: float = 90.0
@export var turn_smooth: float = 10.0
@export var pitch_limit_deg: float = 75.0

@export var vertical_max_speed: float = 6.0
@export var vertical_accel: float = 10.0
@export var vertical_drag: float = 3.0

var yaw_in: float = 0.0
var pitch_in: float = 0.0

var yaw_deg: float = 0.0
var pitch_deg: float = 0.0

func _ready() -> void:
	# Start from current orientation (so it doesn't snap)
	yaw_deg = rotation_degrees.y
	pitch_deg = rotation_degrees.x
	# IMPORTANT: keep roll zero
	rotation_degrees.z = 0.0

func _physics_process(delta: float) -> void:
	# Inputs
	var yaw_target: float = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	# UP = nose down, DOWN = nose up (your request)
	var pitch_target: float = float(Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_UP))
	var throttle: float = float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_S))
	var updown: float = float(Input.is_key_pressed(KEY_SPACE)) - float(Input.is_key_pressed(KEY_SHIFT))

	# Smooth inputs
	yaw_in = lerp(yaw_in, yaw_target, 1.0 - exp(-turn_smooth * delta))
	pitch_in = lerp(pitch_in, pitch_target, 1.0 - exp(-turn_smooth * delta))

	# Integrate yaw/pitch ourselves (no Euler weirdness)
	yaw_deg += yaw_speed_deg * yaw_in * delta
	pitch_deg += pitch_speed_deg * pitch_in * delta
	pitch_deg = clamp(pitch_deg, -pitch_limit_deg, pitch_limit_deg)

	# Build basis from yaw then pitch (roll forced to 0)
	var yaw_rad: float = deg_to_rad(yaw_deg)
	var pitch_rad: float = deg_to_rad(pitch_deg)

	var b := Basis(Vector3.UP, yaw_rad) * Basis(Vector3.RIGHT, pitch_rad)

	# Apply to this body
	var gt := global_transform
	gt.basis = b
	global_transform = gt

	# Forward in the direction you're pointing
	var forward: Vector3 = -global_transform.basis.z
	var desired_h: Vector3 = forward * (throttle * max_speed)

	# Horizontal smoothing
	var a_h: float = accel if abs(throttle) > 0.001 else drag
	var hvel := Vector3(velocity.x, 0.0, velocity.z)
	hvel = hvel.lerp(Vector3(desired_h.x, 0.0, desired_h.z), 1.0 - exp(-a_h * delta))
	velocity.x = hvel.x
	velocity.z = hvel.z

	# Vertical thrust (world up)
	var desired_v: float = updown * vertical_max_speed
	var a_v: float = vertical_accel if abs(updown) > 0.001 else vertical_drag
	velocity.y = lerp(velocity.y, desired_v, 1.0 - exp(-a_v * delta))

	move_and_slide()
