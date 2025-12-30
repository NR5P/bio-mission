extends Node3D

@export var wobble_speed: float = 7.5
@export var wobble_amount: float = 0.14

@export var tilt_amount_deg: float = 16.0
@export var pitch_amount_deg: float = 10.0
@export var follow_smooth: float = 10.0

@export var assumed_max_speed: float = 7.0

@onready var body: MeshInstance3D = $Body
@onready var bacteria: CharacterBody3D = get_parent() as CharacterBody3D

var t: float = 0.0
var base_body_scale: Vector3 = Vector3.ONE

func _ready() -> void:
	base_body_scale = body.scale

func _process(delta: float) -> void:
	if bacteria == null:
		return

	t += delta

	# Horizontal speed 0..1
	var hvel: Vector3 = Vector3(bacteria.velocity.x, 0.0, bacteria.velocity.z)
	var speed01: float = clamp(hvel.length() / assumed_max_speed, 0.0, 1.0)

	# Always slightly alive, more when moving
	var swim: float = 0.25 + 0.75 * speed01

	# Blob squish / pulse
	var s1: float = float(sin(t * wobble_speed)) * wobble_amount * swim
	var s2: float = float(sin(t * wobble_speed * 1.4 + 1.7)) * wobble_amount * swim

	var sx: float = 1.0 + s1
	var sy: float = 1.0 - (s1 * 0.6) + (s2 * 0.2)
	var sz: float = 1.0 + s2

	body.scale = base_body_scale * Vector3(sx, sy, sz)

	# Swimming tilt (bank + pitch) from input
	var turn: float = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	var throttle: float = float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_S))

	var target_roll: float = deg_to_rad(-turn * tilt_amount_deg) * swim
	var target_pitch: float = deg_to_rad(throttle * pitch_amount_deg) * swim

	var target_rot: Vector3 = Vector3(target_pitch, 0.0, target_roll)

	# Smooth visual rotation (does not affect physics)
	var k: float = 1.0 - exp(-follow_smooth * delta)
	rotation = rotation.lerp(target_rot, k)
