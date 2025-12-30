extends CharacterBody3D

@export var speed := 7.0
@export var vertical_speed := 6.0

func _physics_process(delta: float) -> void:
	# Get the active camera
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return

	# Input (WASD)
	var ix := float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	var iz := float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_S))

	# Vertical input
	var iy := float(Input.is_key_pressed(KEY_SPACE)) - float(Input.is_key_pressed(KEY_SHIFT))

	# Camera-relative directions
	var forward := -cam.global_transform.basis.z   # <-- THIS is the fix
	var right := cam.global_transform.basis.x

	# Keep movement level
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()

	# Build movement direction
	var move_dir := (right * ix) + (forward * iz)
	if move_dir.length() > 0:
		move_dir = move_dir.normalized()

	# Apply velocity
	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed
	velocity.y = iy * vertical_speed

	move_and_slide()
