@tool
extends Node

# Global variables
var _location = Vector3()
var _connections = [null, null, null, null]
var _full_connection = [false, false, false, false]

# Street variables
@export var _sizes = Vector3(12, 0, 12)
var _road_width = 3.5
var _sidewalk_width = 2.5
var _sidewalk_height = 0.12

# Initialize location
func init(location: Vector3, sizes: Vector3):
	_location = location
	_sizes = sizes

func set_con_n(d: Knot):
	_connections[0] = d

func set_con_e(d: Knot):
	_connections[1] = d

func set_con_s(d: Knot):
	_connections[2] = d

func set_con_w(d: Knot):
	_connections[3] = d

func set_full_con_n(d: bool):
	_full_connection[0] = d

func set_full_con_e(d: bool):
	_full_connection[1] = d

func set_full_con_s(d: bool):
	_full_connection[2] = d

func set_full_con_w(d: bool):
	_full_connection[3] = d

func set_connections(n: Knot, e: Knot, s: Knot, w: Knot):
	_connections[0] = n
	_connections[1] = e
	_connections[2] = s
	_connections[3] = w

func set_full_connections(n: bool, e: bool, s: bool, w: bool):
	_full_connection[0] = n
	_full_connection[1] = e
	_full_connection[2] = s
	_full_connection[3] = w

func add_connection(k: Knot):
	_connections.append(k)

func generate_mesh(combined_mesh: ArrayMesh):
	# Create plane
	var road_mesh = PlaneMesh.new()
	road_mesh.size = Vector2(_sizes.x, _sizes.z)
	# Surfacetool plane
	var st_road = SurfaceTool.new()
	st_road.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_road.create_from(road_mesh, 0)
	st_road.generate_normals()
	
	combined_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, move_vertices(st_road.commit_to_arrays(), Vector3(_location.x, _location.y, _location.z)))

	for i in range(_connections.size()):
		if _connections[i] != null:
			generate_connection(combined_mesh, _connections[i], _full_connection[i])

func generate_connection(combined_mesh: ArrayMesh, k: Knot, full_connection: bool):
	var v = k._location - _location
	var length
	# if-else for connectors until knot
	if full_connection: length = v.length() - _sizes.x
	else: length = v.length() / 2 - _sizes.x / 2
	var angle = -atan2(v.z, v.x)  # Calculate angle around Y-axis
	
	var offset
	# if-else for connectors until knot
	if full_connection: offset = v.normalized() * v.length() / 2
	else: offset = v.normalized() * (v.length() / 4 + _sizes.x / 4)
	var move_loc = _location + offset
	
	var road_mesh = PlaneMesh.new()
	road_mesh.size = Vector2(_sizes.z, length)
	
	var st_road = SurfaceTool.new()
	st_road.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_road.create_from(road_mesh, 0)
	
	var mesh_array = st_road.commit_to_arrays()
	var vertices = mesh_array[ArrayMesh.ARRAY_VERTEX]
	
	angle += PI / 2
	angle *= -1
	var cos_angle = cos(angle)
	var sin_angle = sin(angle)
	
	for i in range(vertices.size()):
		var vertex = vertices[i]
		var rotated_x = vertex.x * cos_angle - vertex.z * sin_angle
		var rotated_z = vertex.x * sin_angle + vertex.z * cos_angle
		vertex.x = rotated_x
		vertex.z = rotated_z
		vertices[i] = vertex
	
	mesh_array[ArrayMesh.ARRAY_VERTEX] = vertices
	
	move_vertices(mesh_array, move_loc)
	
	# Genrate normals
	st_road.generate_normals()
	
	# Add street to combined_mesh
	combined_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_array)

func move_vertices(mesh: Array, transform: Vector3):
	var vertices = mesh[ArrayMesh.ARRAY_VERTEX]
	
	for i in range(vertices.size()):
		vertices[i].x += transform.x
		vertices[i].y += transform.y
		vertices[i].z += transform.z
	
	mesh[ArrayMesh.ARRAY_VERTEX] = vertices
	return mesh
