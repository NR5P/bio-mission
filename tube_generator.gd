@tool
extends Node3D

# Drag your Path3D (VesselPath) into this in the inspector.
@export var path_node: NodePath

# Tube shape
@export var radius: float = 10.0          # "20m wide" ≈ radius 10 (diameter 20)
@export var sides: int = 24               # 16/24/32 (higher = rounder)
@export var segments_per_meter: float = 2.0  # higher = smoother bends (try 3..6)

# Render controls
@export var inside_visible: bool = true   # normals face inward for inside view
@export var smooth_shading: bool = true

# Material controls (simple built-in)
@export var albedo_color: Color = Color(0.25, 0.05, 0.07, 1.0)
@export var roughness: float = 0.85
@export var specular: float = 0.2

# Glow
@export var use_emission: bool = true
@export var emission_color: Color = Color(0.35, 0.08, 0.08, 1.0)
@export var emission_energy: float = 1.5

# Collision
@export var generate_collision: bool = true
@export var two_sided_collision: bool = true   # ✅ FIX: collide from inside + outside

# Rebuild toggle (nice in editor)
@export var rebuild_now: bool = false:
	set(v):
		rebuild_now = false
		if Engine.is_editor_hint():
			_rebuild()

var mesh_instance: MeshInstance3D = null
var static_body: StaticBody3D = null
var collision_shape: CollisionShape3D = null

func _ready() -> void:
	# Build once on play (and in editor because @tool)
	_rebuild()

func _notification(what: int) -> void:
	# In editor, rebuild when properties change sometimes
	if Engine.is_editor_hint() and what == NOTIFICATION_ENTER_TREE:
		_rebuild()

func _rebuild() -> void:
	var path: Path3D = _get_path()
	if path == null:
		return
	if path.curve == null:
		return
	if path.curve.get_point_count() < 2:
		return

	# Ensure children exist
	mesh_instance = _ensure_mesh_instance()
	if generate_collision:
		_ensure_collision_nodes()

	# Build mesh
	var tube_mesh: ArrayMesh = _build_tube_mesh(path)
	mesh_instance.mesh = tube_mesh
	mesh_instance.material_override = _make_material()

	# Build collision
	if generate_collision:
		_build_collision_from_mesh(tube_mesh)

func _get_path() -> Path3D:
	var p: Node = null
	if path_node != NodePath():
		p = get_node_or_null(path_node)
	if p == null:
		# fallback: try sibling named VesselPath
		p = get_parent().get_node_or_null("VesselPath") if get_parent() != null else null
	return p as Path3D

func _ensure_mesh_instance() -> MeshInstance3D:
	var existing: Node = get_node_or_null("TubeMesh")
	if existing != null and existing is MeshInstance3D:
		return existing as MeshInstance3D

	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "TubeMesh"
	add_child(mi)
	mi.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else null
	return mi

func _ensure_collision_nodes() -> void:
	var sb: Node = get_node_or_null("TubeCollision")
	if sb == null:
		static_body = StaticBody3D.new()
		static_body.name = "TubeCollision"
		add_child(static_body)
		static_body.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else null
	else:
		static_body = sb as StaticBody3D

	var cs: Node = static_body.get_node_or_null("CollisionShape3D")
	if cs == null:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		static_body.add_child(collision_shape)
		collision_shape.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else null
	else:
		collision_shape = cs as CollisionShape3D

func _make_material() -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = albedo_color
	mat.roughness = roughness
	mat.specular = specular

	# Make inside visible (helps if you ever look from odd angles)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	if use_emission:
		mat.emission_enabled = true
		mat.emission = emission_color
		mat.emission_energy_multiplier = emission_energy

	return mat

func _build_tube_mesh(path: Path3D) -> ArrayMesh:
	var curve: Curve3D = path.curve

	# Use baked length to decide how many rings
	var length: float = curve.get_baked_length()
	if length < 0.001:
		length = 1.0

	var rings: int = int(max(2.0, length * segments_per_meter))
	var ring_count: int = rings + 1

	# Pre-sample centers + tangents
	var centers: Array[Vector3] = []
	centers.resize(ring_count)

	var tangents: Array[Vector3] = []
	tangents.resize(ring_count)

	for i in range(ring_count):
		var d: float = length * (float(i) / float(rings))
		var pos: Vector3 = curve.sample_baked(d, true)
		centers[i] = pos

		# Finite-difference tangent
		var eps: float = 0.25
		var d0: float = clamp(d - eps, 0.0, length)
		var d1: float = clamp(d + eps, 0.0, length)
		var p0: Vector3 = curve.sample_baked(d0, true)
		var p1: Vector3 = curve.sample_baked(d1, true)
		var t: Vector3 = (p1 - p0)
		if t.length() < 0.00001:
			t = Vector3.FORWARD
		else:
			t = t.normalized()
		tangents[i] = t

	# Build a stable frame along the curve (parallel transport)
	var frame_t: Array[Vector3] = []
	var frame_n: Array[Vector3] = []
	var frame_b: Array[Vector3] = []
	frame_t.resize(ring_count)
	frame_n.resize(ring_count)
	frame_b.resize(ring_count)

	var t0: Vector3 = tangents[0]
	var up: Vector3 = Vector3.UP
	if abs(t0.dot(up)) > 0.9:
		up = Vector3.RIGHT

	var n0: Vector3 = (up - t0 * up.dot(t0))
	if n0.length() < 0.00001:
		n0 = Vector3.RIGHT
	else:
		n0 = n0.normalized()

	var b0: Vector3 = t0.cross(n0).normalized()
	n0 = b0.cross(t0).normalized()

	frame_t[0] = t0
	frame_n[0] = n0
	frame_b[0] = b0

	var t_prev: Vector3 = t0
	var n_prev: Vector3 = n0

	for i in range(1, ring_count):
		var t_cur: Vector3 = tangents[i]

		var axis: Vector3 = t_prev.cross(t_cur)
		var axis_len: float = axis.length()

		var n_cur: Vector3 = n_prev
		if axis_len > 0.00001:
			axis = axis / axis_len
			var dotv: float = clamp(t_prev.dot(t_cur), -1.0, 1.0)
			var ang: float = acos(dotv)
			var rot: Basis = Basis(axis, ang)
			n_cur = (rot * n_prev).normalized()

		var b_cur: Vector3 = t_cur.cross(n_cur)
		if b_cur.length() < 0.00001:
			b_cur = t_cur.cross(Vector3.UP)
			if b_cur.length() < 0.00001:
				b_cur = t_cur.cross(Vector3.RIGHT)
		b_cur = b_cur.normalized()
		n_cur = b_cur.cross(t_cur).normalized()

		frame_t[i] = t_cur
		frame_n[i] = n_cur
		frame_b[i] = b_cur

		t_prev = t_cur
		n_prev = n_cur

	# Build arrays
	var vert_count: int = ring_count * sides

	var vertices: PackedVector3Array = PackedVector3Array()
	vertices.resize(vert_count)

	var normals: PackedVector3Array = PackedVector3Array()
	normals.resize(vert_count)

	var uvs: PackedVector2Array = PackedVector2Array()
	uvs.resize(vert_count)

	for i in range(ring_count):
		var c: Vector3 = centers[i]
		var n: Vector3 = frame_n[i]
		var b: Vector3 = frame_b[i]

		for j in range(sides):
			var idx: int = i * sides + j
			var a: float = TAU * (float(j) / float(sides))
			var dir: Vector3 = (n * cos(a) + b * sin(a)).normalized()

			vertices[idx] = c + dir * radius
			normals[idx] = (-dir) if inside_visible else dir

			var u: float = float(j) / float(sides)
			var v: float = float(i) / float(rings)
			uvs[idx] = Vector2(u, v)

	var index_count: int = rings * sides * 6
	var indices: PackedInt32Array = PackedInt32Array()
	indices.resize(index_count)

	var w: int = 0
	for i in range(rings):
		for j in range(sides):
			var a0: int = i * sides + j
			var b0i: int = i * sides + ((j + 1) % sides)
			var c0: int = (i + 1) * sides + ((j + 1) % sides)
			var d0: int = (i + 1) * sides + j

			if inside_visible:
				indices[w + 0] = a0
				indices[w + 1] = c0
				indices[w + 2] = b0i
				indices[w + 3] = a0
				indices[w + 4] = d0
				indices[w + 5] = c0
			else:
				indices[w + 0] = a0
				indices[w + 1] = b0i
				indices[w + 2] = c0
				indices[w + 3] = a0
				indices[w + 4] = c0
				indices[w + 5] = d0

			w += 6

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	return mesh

func _build_collision_from_mesh(mesh: ArrayMesh) -> void:
	if collision_shape == null:
		return

	# Concave collision is one-sided (triangle winding).
	# Fix: duplicate faces with reversed winding so it collides from BOTH sides.
	var faces: PackedVector3Array = mesh.get_faces()

	if two_sided_collision and faces.size() >= 3:
		var doubled: PackedVector3Array = PackedVector3Array()
		doubled.resize(faces.size() * 2)

		var w: int = 0
		for i in range(0, faces.size(), 3):
			var a: Vector3 = faces[i]
			var b: Vector3 = faces[i + 1]
			var c: Vector3 = faces[i + 2]

			# original
			doubled[w] = a; w += 1
			doubled[w] = b; w += 1
			doubled[w] = c; w += 1

			# reversed
			doubled[w] = a; w += 1
			doubled[w] = c; w += 1
			doubled[w] = b; w += 1

		faces = doubled

	var shape: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	shape.data = faces
	collision_shape.shape = shape
