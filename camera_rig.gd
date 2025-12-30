extends Node3D

@export var distance := 8.0
@export var min_distance := 4.0
@export var max_distance := 14.0
@export var height := 4.0

@export var yaw_speed := 90.0
@export var zoom_speed := 10.0

@onready var cam: Camera3D = $Camera3D

var yaw_deg := 0.0

func _ready() -> void:
	cam.make_current()

func _process(delta: float) -> void:
	# Arrow keys: orbit + zoom
	if Input.is_key_pressed(KEY_LEFT):
		yaw_deg -= yaw_speed * delta
	if Input.is_key_pressed(KEY_RIGHT):
		yaw_deg += yaw_speed * delta

	if Input.is_key_pressed(KEY_UP):
		distance -= zoom_speed * delta
	if Input.is_key_pressed(KEY_DOWN):
		distance += zoom_speed * delta

	distance = clamp(distance, min_distance, max_distance)

	_update_camera_world()

func _update_camera_world() -> void:
	var target := get_parent() as Node3D
	if target == null:
		return

	var target_pos := target.global_position
	var focus_pos := target_pos + Vector3(0, height * 0.5, 0)

	# Orbit offset in world space (yaw around Y axis)
	var yaw_rad := deg_to_rad(yaw_deg)
	var offset := Vector3(sin(yaw_rad), 0, cos(yaw_rad)) * distance
	offset.y = height

	# Place camera in world space
	cam.global_position = target_pos + offset

	# Aim at bacteria in world space
	cam.look_at(focus_pos, Vector3.UP)
