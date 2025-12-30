extends Node3D

@export var hair_count := 60
@export var hair_length := 0.55
@export var hair_thickness := 0.04
@export var body_radius := 0.5

@export var sway_speed := 4.0
@export var sway_amount_deg := 18.0

var hairs: Array[Node3D] = []
var axes: Array[Vector3] = []
var phase: Array[float] = []

var t := 0.0

func _ready() -> void:
	_build_hairs()

func _process(delta: float) -> void:
	t += delta * sway_speed
	for i in hairs.size():
		var h := hairs[i]
		var a := axes[i]
		var ang := sin(t + phase[i]) * deg_to_rad(sway_amount_deg)
		# base rotation = the hair's "pointing out" direction (already set),
		# then add a small sway around a perpendicular axis
		h.rotation = Vector3.ZERO
		h.rotate(a, ang)

func _build_hairs() -> void:
	# Clear old hairs if you re-run in editor / hot reload
	for c in get_children():
		c.queue_free()
	hairs.clear()
	axes.clear()
	phase.clear()

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in hair_count:
		# Hair pivot node
		var pivot := Node3D.new()
		add_child(pivot)

		# Random point on sphere (uniform)
		var u := rng.randf()
		var v := rng.randf()
		var theta := 2.0 * PI * u
		var phi := acos(2.0 * v - 1.0)

		var dir := Vector3(
			sin(phi) * cos(theta),
			cos(phi),
			sin(phi) * sin(theta)
		).normalized()

		# Place pivot on body surface
		pivot.position = dir * body_radius

		# Aim pivot outward (so local -Z points outward or similar)
		# We'll orient pivot so its "up" is dir by using look_at.
		# Aim it away from center:
		pivot.look_at(pivot.global_position + dir, Vector3.UP)

		# Hair mesh
		var hair := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = hair_thickness
		cyl.bottom_radius = hair_thickness * 0.9
		cyl.height = hair_length
		hair.mesh = cyl

		# Cylinder is centered; push it outward so it starts at the body surface
		hair.position = Vector3(0, hair_length * 0.5, 0)
		pivot.add_child(hair)

		hairs.append(pivot)

		# Pick a sway axis roughly perpendicular to dir
		var perp := dir.cross(Vector3.UP)
		if perp.length() < 0.01:
			perp = dir.cross(Vector3.RIGHT)
		perp = perp.normalized()
		axes.append(perp)

		phase.append(rng.randf_range(0.0, TAU))
