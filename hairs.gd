extends Node3D

@export var hair_count := 140

@export var hair_length := 0.30
@export var hair_thickness := 0.03

# Capsule body shape aligned along local Z (rod pointing forward/back)
@export var body_radius := 0.45
@export var body_half_length := 0.75  # half the straight middle section length (along Z)

@export var sway_speed := 4.0
@export var sway_amount_deg := 15.0

var pivots: Array[Node3D] = []
var base_basis: Array[Basis] = []
var sway_axes_local: Array[Vector3] = []
var phases: Array[float] = []

var t := 0.0

func _ready() -> void:
	_build_hairs()

func _process(delta: float) -> void:
	t += delta * sway_speed
	for i in pivots.size():
		var p := pivots[i]
		var ang := sin(t + phases[i]) * deg_to_rad(sway_amount_deg)
		var wiggle := Basis(sway_axes_local[i], ang)

		# Keep the "point outward" orientation, add a small wiggle on top
		p.basis = base_basis[i] * wiggle

func _build_hairs() -> void:
	# Clear existing children
	for c in get_children():
		c.queue_free()

	pivots.clear()
	base_basis.clear()
	sway_axes_local.clear()
	phases.clear()

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in hair_count:
		var pivot := Node3D.new()
		add_child(pivot)

		# ---- Sample a point on a capsule surface aligned along local Z ----
		var pos: Vector3
		var normal: Vector3

		# More hairs on the side (cylinder) than the end caps
		var use_cylinder := rng.randf() < 0.70

		if use_cylinder:
			# Cylinder section: z in [-body_half_length, +body_half_length]
			var a := rng.randf_range(0.0, TAU)
			var z := rng.randf_range(-body_half_length, body_half_length)

			pos = Vector3(cos(a) * body_radius, sin(a) * body_radius, z)
			normal = Vector3(cos(a), sin(a), 0.0).normalized()
		else:
			# Caps: choose which end
			var cap_sign := -1.0 if rng.randf() < 0.5 else 1.0
			var cap_center := Vector3(0.0, 0.0, cap_sign * body_half_length)

			# Random direction on a sphere, then force to correct hemisphere
			var u := rng.randf()
			var v := rng.randf()
			var theta := TAU * u
			var phi := acos(2.0 * v - 1.0)

			var d := Vector3(
				sin(phi) * cos(theta),
				cos(phi),
				sin(phi) * sin(theta)
			).normalized()

			# Force direction to match cap hemisphere
			if sign(d.z) != cap_sign:
				d.z *= -1.0

			pos = cap_center + d * body_radius
			normal = (pos - cap_center).normalized()

		pivot.position = pos

		# ---- Orient pivot so local +Y points outward along normal ----
		var y_axis := normal
		var x_axis := Vector3.UP.cross(y_axis)
		if x_axis.length() < 0.01:
			x_axis = Vector3.RIGHT.cross(y_axis)
		x_axis = x_axis.normalized()
		var z_axis := x_axis.cross(y_axis).normalized()

		var b := Basis(x_axis, y_axis, z_axis)
		pivot.basis = b

		pivots.append(pivot)
		base_basis.append(b)

		# ---- Hair mesh (Cylinder height is along local Y) ----
		var hair := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = hair_thickness
		cyl.bottom_radius = hair_thickness * 0.9
		cyl.height = hair_length
		hair.mesh = cyl

		# Move cylinder so it starts at the surface and extends outward
		hair.position = Vector3(0.0, hair_length * 0.5, 0.0)
		pivot.add_child(hair)

		# ---- Wiggle axis (local X/Z plane, perpendicular to hair's +Y) ----
		var r := rng.randf_range(0.0, TAU)
		var axis_local := (Vector3.RIGHT * cos(r) + Vector3.FORWARD * sin(r)).normalized()
		sway_axes_local.append(axis_local)

		phases.append(rng.randf_range(0.0, TAU))
