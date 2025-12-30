extends CharacterBody3D

@export var max_speed := 7.0
@export var accel := 10.0
@export var drag := 3.0              # lower = more glide (more “bacteria”)

@export var vertical_max_speed := 5.0
@export var vertical_accel := 10.0
@export var vertical_drag := 3.0

@export var turn_speed_deg := 140.0
@export var turn_smooth := 7.0       # lower = floatier turn, higher = snappier

var turn_input := 0.0

func _physics_process(delta: float) -> void:
	var target_turn := float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	var throttle := float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_S))
	var updown := float(Input.is_key_pressed(KEY_SPACE)) - float(Input.is_key_pressed(KEY_SHIFT))

	# Smooth turning (no robotic snap)
	turn_input = lerp(turn_input, target_turn, 1.0 - exp(-turn_smooth * delta))
	rotation.y += deg_to_rad(turn_speed_deg) * turn_input * delta

	# Desired horizontal velocity (in facing direction)
	var forward := -global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	var desired_hvel := forward * (throttle * max_speed)

	# Current horizontal velocity
	var hvel := Vector3(velocity.x, 0.0, velocity.z)

	# Accelerate / drag
	var a := accel if abs(throttle) > 0.001 else drag
	hvel = hvel.lerp(desired_hvel, 1.0 - exp(-a * delta))

	velocity.x = hvel.x
	velocity.z = hvel.z

	# Vertical floaty motion
	var desired_v := updown * vertical_max_speed
	var a_v := vertical_accel if abs(updown) > 0.001 else vertical_drag
	velocity.y = lerp(velocity.y, desired_v, 1.0 - exp(-a_v * delta))

	move_and_slide()
