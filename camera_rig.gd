extends Node3D

@export var distance: float = 8.0
@export var min_distance: float = 4.0
@export var max_distance: float = 14.0

@export var yaw_speed: float = 90.0
@export var pitch_speed: float = 80.0
@export var zoom_speed: float = 10.0

@export var min_pitch_deg: float = -75.0
@export var max_pitch_deg: float = 75.0

@onready var cam: Camera3D = $Camera3D

var yaw_deg: float = 0.0
var pitch_deg: float = -10.0   # slight downward angle by default

func _ready() -> void:
	cam.make_current()

func _process(delta: float) -> void:
	# Yaw (orbit left/right)
	if Input.is_key_pressed(KEY_J):
		yaw_deg -= yaw_speed * delta
	if Input.is_key_pressed(KEY_L):
		yaw_deg += yaw_speed * delta

	# Pitch (orbit up/down)
	if Input.is_key_pressed(KEY_U):
		pitch_deg += pitch_speed * delta
	if Input.is_key_pressed(KEY_O):
		pitch_deg -= pitch_speed * delta

	pitch_deg = clamp(pitch_deg, min_pitch_deg, max_pitch_deg)

	# Zoom
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

	# Convert spherical coords to Cartesian
	var yaw_rad: float = deg_to_rad(yaw_deg)
	var pitch_rad: float = deg_to_rad(pitch_deg)

	var x := cos(pitch_rad) * sin(yaw_rad)
	var y := sin(pitch_rad)
	var z := cos(pitch_rad) * cos(yaw_rad)

	var offset := Vector3(x, y, z) * distance

	cam.global_position = target_pos + offset
	cam.look_at(target_pos, Vector3.UP)
