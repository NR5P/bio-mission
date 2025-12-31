extends CharacterBody3D

@export var max_speed: float = 7.0
@export var accel: float = 10.0
@export var drag: float = 3.0

@export var vertical_max_speed: float = 5.0
@export var vertical_accel: float = 10.0
@export var vertical_drag: float = 3.0

@export var turn_speed_deg: float = 140.0
@export var turn_smooth: float = 7.0

# How much you can "bend" your path while gliding
@export var glide_turn_strength: float = 1.0  # 0 = no glide steering, 1 = full

var turn_input: float = 0.0

func _physics_process(delta: float) -> void:
	var target_turn: float = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	var throttle: float = float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_S))
	var updown: float = float(Input.is_key_pressed(KEY_SPACE)) - float(Input.is_key_pressed(KEY_SHIFT))

	# Smooth turning input
	turn_input = lerp(turn_input, target_turn, 1.0 - exp(-turn_smooth * delta))

	# Current horizontal velocity
	var hvel: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var hspeed: float = hvel.length()
	var speed01: float = clamp(hspeed / max_speed, 0.0, 1.0)

	# Turn rate (optionally reduce turning when almost stopped)
	var turn_rate: float = deg_to_rad(turn_speed_deg) * turn_input
	var turn_scale: float = 0.15 + 0.85 * speed01  # less spin-in-place
	var turn_ang: float = turn_rate * turn_scale * delta

	# 1) Rotate the current velocity vector to "curve" naturally (bacteria swim feel)
	if hspeed > 0.01 and abs(turn_ang) > 0.00001 and glide_turn_strength > 0.0:
		var rot := Basis(Vector3.UP, turn_ang * glide_turn_strength)
		hvel = rot * hvel

	# 2) Apply forward/back acceleration along facing direction
	rotation.y += turn_ang  # visuals follow the turn (yaw only)

	var forward: Vector3 = -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var desired_hvel: Vector3 = forward * (throttle * max_speed)

	var a: float = accel if abs(throttle) > 0.001 else drag
	hvel = hvel.lerp(desired_hvel, 1.0 - exp(-a * delta))

	# Clamp horizontal speed
	if hvel.length() > max_speed:
		hvel = hvel.normalized() * max_speed

	velocity.x = hvel.x
	velocity.z = hvel.z

	# Vertical floaty motion
	var desired_v: float = updown * vertical_max_speed
	var a_v: float = vertical_accel if abs(updown) > 0.001 else vertical_drag
	velocity.y = lerp(velocity.y, desired_v, 1.0 - exp(-a_v * delta))

	move_and_slide()
