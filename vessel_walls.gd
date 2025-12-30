extends StaticBody3D

@export var radius: float = 20.0          # should match VesselVisual radius (a bit smaller is ok)
@export var length: float = 200.0         # should match VesselVisual height/length
@export var segments: int = 20            # more = rounder wall

@export var wall_thickness: float = 1.2   # thickness of wall colliders
@export var wall_height: float = 6.0      # height of each segment around the ring (bigger = more coverage)

func _ready() -> void:
	build_walls()

func build_walls() -> void:
	# Clear old generated shapes
	for c in get_children():
		c.queue_free()

	for i in range(segments):
		var a: float = TAU * float(i) / float(segments)

		var shape := BoxShape3D.new()
		shape.size = Vector3(wall_thickness, wall_height, length)

		var cs := CollisionShape3D.new()
		cs.shape = shape
		add_child(cs)

		# Place each box around a circle in X/Y; tube runs along Z
		cs.position = Vector3(cos(a) * radius, sin(a) * radius, 0.0)

		# Rotate so the box is tangent to the ring
		cs.rotation = Vector3(0.0, 0.0, a)
