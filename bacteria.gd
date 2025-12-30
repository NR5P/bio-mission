extends CharacterBody3D

@export var speed := 7.0
@export var vertical_speed := 5.0

func _physics_process(delta: float) -> void:
	# Horizontal movement (XZ)
	var ix := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var iz := Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	# Vertical movement (Y)
	var iy := 0.0
	if Input.is_key_pressed(KEY_SPACE):
		iy += 1.0
	if Input.is_key_pressed(KEY_SHIFT):
		iy -= 1.0

	var direction := Vector3(ix, iy, iz)
	if direction.length() > 0:
		direction = direction.normalized()

	velocity = direction * speed
	move_and_slide()
