extends Node3D

@export var wobble_speed := 2.2
@export var wobble_amount := 0.06

@onready var body: MeshInstance3D = $Body

var t := 0.0
var base_scale := Vector3.ONE

func _ready() -> void:
	base_scale = body.scale

func _process(delta: float) -> void:
	t += delta * wobble_speed

	# Subtle non-uniform scale wobble
	var sx := 1.0 + sin(t * 1.00) * wobble_amount
	var sy := 1.0 + sin(t * 1.37) * wobble_amount
	var sz := 1.0 + sin(t * 1.71) * wobble_amount
	body.scale = Vector3(base_scale.x * sx, base_scale.y * sy, base_scale.z * sz)
