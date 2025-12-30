extends CharacterBody3D

@export var speed := 7.0
@export var vertical_speed := 6.0
@export var turn_speed_deg := 160.0  # how fast it turns

func _physics_process(delta: float) -> void:
	# Get the active camera
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return

	# Inputs
	var turn := float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))  # A/D
	var throttle := float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_S))  # W/S
	var iy := float(Input.is_key_pressed(KEY_SPACE)) - float(Input.is_key_pressed(KEY_SHIFT))  # up/down

	# --- Turn the bacteria like a car (yaw rotation) ---
	rotation.y += deg_to_rad(turn_speed_deg) * turn * delta

	# --- Move forward/back in the bacteria's facing direction ---
	# In Godot, -Z is "forward" for a Node3D
	var forward := -global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	var move_dir := forward * throttle

	# Apply velocity
	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed
	velocity.y = iy * vertical_speed

	move_and_slide()
