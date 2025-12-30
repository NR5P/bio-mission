extends CharacterBody3D

@export var speed := 7.0
@export var vertical_speed := 6.0

func _physics_process(delta: float) -> void:
	# WASD movement on X/Z
	var ix := float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	var iz := float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))

	# Vertical movement on Y
	var iy := float(Input.is_key_pressed(KEY_SPACE)) - float(Input.is_key_pressed(KEY_SHIFT))

	var dir := Vector3(ix, iy, iz)
	if dir.length() > 0:
		dir = dir.normalized()

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	velocity.y = dir.y * vertical_speed

	move_and_slide()
