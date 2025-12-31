extends Node3D

@export var distance: float = 8.0
@export var min_distance: float = 4.0
@export var max_distance: float = 14.0
@export var height: float = 4.0

@export var yaw_speed: float = 90.0
@export var zoom_speed: float = 10.0

@onready var cam: Camera3D = $Camera3D

var yaw_deg: float = 0.0

func _ready() -> void:
	cam.make_current()

func _process(delta: float) -> void:
	# J/L orbit camera
	if Input.is_key_pressed(KEY_J):
		yaw_deg -= yaw_speed * delta
	if Input.is_key_pressed(KEY_L):
		yaw_deg += yaw_speed * delta

	# I/K zoom camera
	if Input.is_key_pressed(KEY_I):
		distance -= zoom_speed * delta
	if Input.is_key_pressed(KEY_K):
		distance += zoom_speed * delta

	distance = clamp(distance, min_distance, max_distance)
	_update_camera_world()

func _update_camera_world() -> void:
	var target := get_parent() as Node3D
	if target == null:
		return

	var target_pos := target.global_position
	var focus_pos := target_pos + Vector3(0, height * 0.5, 0)

	var yaw_rad := deg_to_rad(yaw_deg)
	var offset := Vector3(sin(yaw_rad), 0.0, cos(yaw_rad)) * distance
	offset.y = height

	cam.global_position = target_pos + offset
	cam.look_at(focus_pos, Vector3.UP)
