@tool
extends MeshInstance3D

# Enums
enum Block_type { Blocks, Suburban, Industry }

# Scenes
var knots = preload("res://Scenes/knot.tscn")
var blocks = preload("res://Scenes/block.tscn")

# Materials
var mat_street = preload("res://Materials/M_Street.tres")

# Global variables for street generation
var _size = Vector2(1000, 1000)
var _knot_colums : int = 5
var _knot_rows : int = 5
var _street_size = Vector2(12.0, 12.0)
var _block_street_size = Vector2(12.0, 12.0)
var _grid = false
var _knots = []
var _cams = []
var _cams_pos = [Vector3(-160, 220, -150), Vector3(-160, 220, 1150), Vector3(1160, 220, 1150),
Vector3(1160, 220, -150), Vector3(494, 606.671, 1383.476), Vector3(500, 1000, 500)]

# Noise variables for block generation
var noise = FastNoiseLite.new()
var _seed = randi()
var _seed_text : String = ""
@export var noise_frequency = 0.5
@export var noise_amplitude = 0.1
@export var noise_octaves = 6

@export var rebuild: bool:
	set(value):
		rebuild_streets()

func _ready():
	for i in 6:
		var s = "/root/main_scene/Cam_" + str(i + 1)
		var cam = get_node_or_null(s)
		if cam:
			_cams.append(cam)

func setup():
	# Set noise seed based on user input
	if _seed_text.is_empty():
		_seed = randi()
	else:
		if _seed_text.is_valid_int():
			_seed = int(_seed_text)
	
	# Set noise variables
	noise.seed = _seed
	noise.frequency = noise_frequency
	noise.fractal_octaves = noise_octaves
	
	# Create abstract knots
	_knots = []
	for i in _knot_colums:
		_knots.append([])
		for j in _knot_rows:
			var knot = knots.instantiate()
			knot.init(Vector3(i * _size.x / (_knot_colums - 1), 0, j * _size.y / (_knot_rows - 1)), Vector3(_street_size.x, 0, _street_size.y))
			_knots[i].append(knot)
	
	# Set grid-like connections of knots
	for i in range(_knots.size()):
		if i == 0:
			for j in range(_knots[i].size()):
				if j == 0:
					_knots[i][j].set_connections(null, _knots[i + 1][j], _knots[i][j + 1], null)
				elif j == _knots[i].size() - 1:
					_knots[i][j].set_connections(_knots[i][j - 1], _knots[i + 1][j], null, null)
				else:
					_knots[i][j].set_connections(_knots[i][j - 1], _knots[i + 1][j], _knots[i][j + 1], null)
		elif i == _knots.size() - 1:
			for j in range(_knots[i].size()):
				if j == 0:
					_knots[i][j].set_connections(null, null, _knots[i][j + 1], _knots[i - 1][j])
				elif j == _knots[i].size() - 1:
					_knots[i][j].set_connections(_knots[i][j - 1], null, null, _knots[i - 1][j])
				else:
					_knots[i][j].set_connections(_knots[i][j - 1], null, _knots[i][j + 1], _knots[i - 1][j])
		else:
			for j in range(_knots[i].size()):
				if j == 0:
					_knots[i][j].set_connections(null, _knots[i + 1][j], _knots[i][j + 1], _knots[i - 1][j])
				elif j == _knots[i].size() - 1:
					_knots[i][j].set_connections(_knots[i][j - 1], _knots[i + 1][j], null, _knots[i - 1][j])
				else:
					_knots[i][j].set_connections(_knots[i][j - 1], _knots[i + 1][j], _knots[i][j + 1], _knots[i - 1][j])
	
	# Generate blocks surrounded by the knots
	for i in range(_knots.size() - 1):
		for j in range(_knots[i].size() - 1):
			var location = (_knots[i][j]._location + _knots[i + 1][j]._location + _knots[i + 1][j + 1]._location + _knots[i][j + 1]._location) / 4
			var size = Vector2(_knots[i + 1][j]._location.x - _knots[i][j]._location.x - _knots[i][j]._sizes.x, _knots[i + 1][j + 1]._location.z - _knots[i + 1][j]._location.z - _knots[i + 1][j]._sizes.z)
			var block = blocks.instantiate()
			block.position = location
			block._size = size
			block._grid = _grid
			block._street_size = _block_street_size
			if noise.get_noise_2d(i, j) <= 0:
				block._area_density = noise.get_noise_2d(i, j)
				block._block_type = Block_type.Suburban
			else:
				block._area_density = noise.get_noise_2d(i, j)
				block._block_type = Block_type.Blocks
			block.generate_mesh()
			self.add_child(block)

# Rebuild streets and blocks
func rebuild_streets():
	# Delete children
	for i in range(get_children().size()):
		get_child(i).queue_free()
	
	# Generate abstract knots and blocks
	setup()
	
	var combined_mesh = ArrayMesh.new()
	
	# Generate mesh from knots
	for i in range(_knots.size()):
		for j in range(_knots[i].size()):
			_knots[i][j].generate_mesh(combined_mesh)
			if combined_mesh.get_surface_count() >= 100:
				combined_mesh = combine_surfaces(combined_mesh)
	combined_mesh = combine_surfaces(combined_mesh)
	combined_mesh.surface_set_material(0, mat_street)
	self.mesh = combined_mesh
	
	# Delete abstract knots
	for i in range(_knots.size()):
		for j in range(_knots[i].size()):
			_knots[i][j].queue_free()

# Combines surfaces to one - needed because max surface count is 255
func combine_surfaces(original_mesh: ArrayMesh):
	var combined_mesh = ArrayMesh.new()
	var st = SurfaceTool.new()
	
	# Begin creating the combined surface with triangles as the primitive type
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Iterate through each surface in the original mesh
	for surface in range(original_mesh.get_surface_count()):
		# Add the vertices and other attributes from the arrays to the SurfaceTool
		st.append_from(original_mesh, surface, Transform3D())
	
	# Commit the combined arrays to the new mesh
	st.generate_normals()
	combined_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	
	return combined_mesh

# Set randomizes 
func rand_block_type():
	var num = randi_range(0, 1)
	
	if num == 0:
		return Block_type.Blocks
	elif num == 1:
		return Block_type.Suburban
	elif num == 2:
		return Block_type.Industry

func set_cam_positions():
	for i in _cams.size():
		if i == 1:
			_cams[i].position = Vector3(_cams_pos[i].x, _cams_pos[i].y, _size.y + 150)
		elif i == 2:
			_cams[i].position = Vector3(_size.x + 160, _cams_pos[i].y, _size.y + 150)
		elif i == 3:
			_cams[i].position = Vector3(_size.x + 160, _cams_pos[i].y, _cams_pos[i].z)
		elif i == 4:
			_cams[i].position = Vector3((_size.x - _street_size.x) / 2, _cams_pos[i].y, (1383.476 + (_size.y + 383.48)) / 2)
			if _size.x >= _size.y:
				_cams[i].size = _size.x / 2 + 200
			else:
				_cams[i].size = _size.y / 2 + 200
		elif i == 5:
			_cams[i].position = Vector3((_size.x) / 2, _cams_pos[i].y, (_size.y) / 2)
			if _size.x >= _size.y:
				_cams[i].size = _size.x + 50
			else:
				_cams[i].size = _size.y + 50
		

func _on_button_pressed():
	rebuild_streets()
	set_cam_positions()

func _on_c_grid_toggled(toggled_on):
	_grid = toggled_on

func _on_s_city_size_x_value_changed(value):
	_size.x = value

func _on_s_city_size_y_value_changed(value):
	_size.y = value

func _on_s_highway_layout_x_value_changed(value):
	_knot_colums = round(value)

func _on_s_highway_layout_y_value_changed(value):
	_knot_rows = round(value)

func _on_s_highway_size_value_changed(value):
	_street_size = Vector2(value, value)

func _on_s_street_size_value_changed(value):
	_block_street_size = Vector2(value, value)

func _on_cam_1_pressed():
	_cams[0].make_current()

func _on_cam_2_pressed():
	_cams[1].make_current()

func _on_cam_3_pressed():
	_cams[2].make_current()

func _on_cam_4_pressed():
	_cams[3].make_current()

func _on_cam_5_pressed():
	_cams[4].make_current()

func _on_cam_6_pressed():
	_cams[5].make_current()

func _on_line_edit_text_changed(new_text):
	_seed_text = new_text
