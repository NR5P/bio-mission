extends Node3D

@export var hair_count: int = 140
@export var hair_length: float = 0.30
@export var hair_thickness: float = 0.03

@export var body_radius: float = 0.45
@export var body_half_length: float = 0.75

@export var sway_speed: float = 4.0
@export var sway_amount_deg: float = 15.0

# Hair color controls
@export var hair_color: Color = Color(0.85, 0.92, 0.65, 1.0)
@export var hair_roughness: float = 0.9
@export var hair_specular: float = 0.05

# NEW: emission/glow controls
@export var hair_emission_color: Color = Color(0.7, 1.0, 0.6, 1.0)
@export var hair_emission_energy: float = 1.5

# --- Fluid pushback (per-hair, realistic) ---
@export var max_flow_bend_deg: float = 85.0
@export var flow_strength: float = 1.6
@export var assumed_max_speed: float = 10.0
@export var flow_smooth: float = 22.0

var pivots: Array[Node3D] = []
var base_basis: Array[Basis] = []
var sway_axes_local: Array[Vector3] = []
var phases: Array[float] = []

var t: float = 0.0
var hair_material: StandardMaterial3D

var bacteria: CharacterBody3D = null
var vel_self_smoothed: Vector3 = Vector3.ZERO

func _ready() -> void:
	# Find the CharacterBody3D up the tree
	var p: Node = get_parent()
	while p != null and not (p is CharacterBody3D):
		p = p.get_parent()
	bacteria = p as CharacterBody3D

	hair_material = StandardMaterial3D.new()
	hair_material.albedo_color = hair_color
	hair_material.roughness = hair_roughness
	hair_material.specular = hair_specular

	# NEW: glow/emission
	hair_material.emission_enabled = true
	hair_material.emission = hair_emission_color
	hair_material.emission_energy_multiplier = hair_emission_energy

	_build_hairs()

func _process(delta: float) -> void:
	t += delta * sway_speed

	var vel_self: Vector3 = Vector3.ZERO
	if bacteria != null:
		var v_world: Vector3 = bacteria.velocity
		if v_world.length() > 0.001:
			var inv_self: Basis = global_transform.basis.inverse()
			vel_self = inv_self * v_world

	var k: float = 1.0 - exp(-flow_smooth * delta)
	vel_self_smoothed = vel_self_smoothed.lerp(vel_self, k)

	var speed01: float = pow(clamp(vel_self_smoothed.length() / assumed_max_speed, 0.0, 1.0), 0.5)
	var max_bend_rad: float = deg_to_rad(max_flow_bend_deg) * flow_strength * speed01

	for i in range(pivots.size()):
		var wig_ang: float = float(sin(t + phases[i])) * deg_to_rad(sway_amount_deg)
		var wiggle: Basis = Basis(sway_axes_local[i], wig_ang)

		var normal_self: Vector3 = (base_basis[i] * Vector3.UP).normalized()

		var v: Vector3 = vel_self_smoothed
		var v_tangent: Vector3 = v - normal_self * v.dot(normal_self)

		var flow_bend: Basis = Basis.IDENTITY
		if v_tangent.length() > 0.001 and max_bend_rad > 0.0:
			var back_tangent: Vector3 = (-v_tangent).normalized()
			var target_self: Vector3 = (normal_self + back_tangent * max_bend_rad).normalized()

			var axis_self: Vector3 = normal_self.cross(target_self)
			var axis_len: float = axis_self.length()
			if axis_len > 0.00001:
				axis_self /= axis_len
				var dotv: float = clamp(normal_self.dot(target_self), -1.0, 1.0)
				var ang: float = acos(dotv)
				flow_bend = Basis(axis_self, ang)

		pivots[i].basis = (flow_bend * base_basis[i]) * wiggle

func _build_hairs() -> void:
	for c in get_children():
		c.queue_free()

	pivots.clear()
	base_basis.clear()
	sway_axes_local.clear()
	phases.clear()

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()

	for i in range(hair_count):
		var pivot: Node3D = Node3D.new()
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
			var cap_center: Vector3 = Vector3(0.0, cap_sign * body_half_length, 0.0)

			var u: float = rng.randf()
			var v: float = rng.randf()
			var theta: float = TAU * u
			var phi: float = acos(2.0 * v - 1.0)

			var d: Vector3 = Vector3(
				sin(phi) * cos(theta),
				cos(phi),
				sin(phi) * sin(theta)
			).normalized()

			if sign(d.y) != cap_sign:
				d.y *= -1.0

			pos = cap_center + d * body_radius
			normal = (pos - cap_center).normalized()

		pivot.position = pos

		var y_axis: Vector3 = normal
		var x_axis: Vector3 = Vector3.UP.cross(y_axis)
		if x_axis.length() < 0.01:
			x_axis = Vector3.RIGHT.cross(y_axis)
		x_axis = x_axis.normalized()
		var z_axis: Vector3 = x_axis.cross(y_axis).normalized()

		var b: Basis = Basis(x_axis, y_axis, z_axis)
		pivot.basis = b

		pivots.append(pivot)
		base_basis.append(b)

		var hair: MeshInstance3D = MeshInstance3D.new()
		var cyl: CylinderMesh = CylinderMesh.new()
		cyl.top_radius = hair_thickness
		cyl.bottom_radius = hair_thickness * 0.9
		cyl.height = hair_length
		hair.mesh = cyl
		hair.material_override = hair_material

		hair.position = Vector3(0.0, hair_length * 0.5, 0.0)
		pivot.add_child(hair)

		var r: float = rng.randf_range(0.0, TAU)
		sway_axes_local.append((Vector3.RIGHT * cos(r) + Vector3.FORWARD * sin(r)).normalized())
		phases.append(rng.randf_range(0.0, TAU))
