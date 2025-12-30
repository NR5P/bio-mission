extends Node3D

@export var hair_count: int = 140
@export var hair_length: float = 0.30
@export var hair_thickness: float = 0.03

# Capsule body shape aligned along local Y (CapsuleMesh default)
@export var body_radius: float = 0.45
@export var body_half_length: float = 0.75

@export var sway_speed: float = 4.0
@export var sway_amount_deg: float = 15.0

# Hair color controls
@export var hair_color: Color = Color(0.85, 0.92, 0.65, 1.0) # pale yellow-green
@export var hair_roughness: float = 0.9
@export var hair_specular: float = 0.05

var pivots: Array[Node3D] = []
var base_basis: Array[Basis] = []
var sway_axes_local: Array[Vector3] = []
var phases: Array[float] = []

var t: float = 0.0
var hair_material: StandardMaterial3D

func _ready() -> void:
	# Create ONE shared material so we don't allocate 140+ materials
	hair_material = StandardMaterial3D.new()
	hair_material.albedo_color = hair_color
	hair_material.roughness = hair_roughness
	hair_material.specular = hair_specular

	_build_hairs()

func _process(delta: float) -> void:
	t += delta * sway_speed
	for i in pivots.size():
		var ang: float = float(sin(t + phases[i])) * deg_to_rad(sway_amount_deg)
		var wiggle: Basis = Basis(sway_axes_local[i], ang)
		pivots[i].basis = base_basis[i] * wiggle

func _build_hairs() -> void:
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

		var pos: Vector3
		var normal: Vector3

		var use_cylinder: bool = rng.randf() < 0.70

		if use_cylinder:
			var a: float = rng.randf_range(0.0, TAU)
			var y: float = rng.randf_range(-body_half_length, body_half_length)

			pos = Vector3(cos(a) * body_radius, y, sin(a) * body_radius)
			normal = Vector3(cos(a), 0.0, sin(a)).normalized()
		else:
			var cap_sign: float = -1.0 if rng.randf() < 0.5 else 1.0
			var cap_center := Vector3(0.0, cap_sign * body_half_length, 0.0)

			var u: float = rng.randf()
			var v: float = rng.randf()
			var theta: float = TAU * u
			var phi: float = acos(2.0 * v - 1.0)

			var d := Vector3(
				sin(phi) * cos(theta),
				cos(phi),
				sin(phi) * sin(theta)
			).normalized()

			if sign(d.y) != cap_sign:
				d.y *= -1.0

			pos = cap_center + d * body_radius
			normal = (pos - cap_center).normalized()

		pivot.position = pos

		# Orient pivot so local +Y points outward along normal
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

		# Hair mesh (Cylinder height is along local Y)
		var hair := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = hair_thickness
		cyl.bottom_radius = hair_thickness * 0.9
		cyl.height = hair_length
		hair.mesh = cyl

		# Apply shared material (color!)
		hair.material_override = hair_material

		# Extend outward from surface
		hair.position = Vector3(0.0, hair_length * 0.5, 0.0)
		pivot.add_child(hair)

		# Wiggle axis perpendicular to local +Y (mix of local X/Z)
		var r: float = rng.randf_range(0.0, TAU)
		sway_axes_local.append((Vector3.RIGHT * cos(r) + Vector3.FORWARD * sin(r)).normalized())
		phases.append(rng.randf_range(0.0, TAU))
