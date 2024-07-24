@tool
extends MeshInstance3D

# Enums
enum Block_type { Blocks, Suburban, Industry }
enum Skyscraper_type { Low, Mid, High }
enum House_type { Small, Mid, Large }

# Classes
class Area:
	var _area_size = Vector2(0,0)
	
	func set_size(v: Vector2):
		_area_size = v

# Scenes
var knots = preload("res://Scenes/knot.tscn")
var properties = preload("res://Scenes/property.tscn")

# Materials
var _mat_grass = preload("res://Materials/M_Grass.tres")
var _mat_asphalt = preload("res://Materials/M_Asphalt.tres")
var _mat_sidewalk = preload("res://Materials/M_Sidewalk.tres")
var _mat_street = preload("res://Materials/M_Street.tres")

# Variables
@export var _size = Vector2(1000.0, 1000.0)
var _grid = false
var _block_type = Block_type.Suburban
var _skyscraper_type = Skyscraper_type.Low
var _house_type = House_type.Small
var _area_density : float = 0.0
var _min_areal_size = Vector2(50.0, 50.0)
var _prop_width : float = 50
var _prop_depth : float = 50
var _street_size = Vector2(8.0, 8.0)
var _sidewalk_width = 2.5
var _sidewalk_height = 0.12

@export var rebuild: bool:
	set(value):
		generate_mesh()

# Generates the final mesh for the block
func generate_mesh():
	
	# Generate areas and buildings
	generate_block()

# Generate areas and buildings
func generate_block():
	# Resetting block
	for i in range(get_children().size()):
		get_child(i).queue_free()
	# Create final ArrayMesh
	var combined_mesh = ArrayMesh.new()
	match _block_type:
		# Generation for type Block
		Block_type.Blocks:
			# Block setup
			if _area_density <= 0.4:
				_skyscraper_type = Skyscraper_type.Low
				_min_areal_size = Vector2(80, 80)
			elif _area_density <= 0.8:
				_skyscraper_type = Skyscraper_type.Mid
				_min_areal_size = Vector2(90, 90)
			else:
				_skyscraper_type = Skyscraper_type.High
				_min_areal_size = Vector2(100, 100)
			
			# Get areal amounts within grid
			var area_amount_x = max(1, floori(_size.x / max(_min_areal_size.x, 1)))
			var area_amount_y = max(1, floori(_size.y / max(_min_areal_size.y, 1)))
			# Array for later generating knots (streets)
			var area_amount_y_colums = []
			var randy
			# ArrayMeshes to combine in final mesh
			var ground_arr = ArrayMesh.new()
			var sidewalk_arr = ArrayMesh.new()
			# Generate for each area the buildings
			for o in area_amount_x:
				if !_grid:
					randy = randi_range(1, area_amount_y)
					area_amount_y_colums.append(randy)
				else:
					randy = area_amount_y
					area_amount_y_colums.append(randy)
				for p in randy:
					var area = Area.new()
					if area_amount_x > 0 and randy > 0:
						area.set_size(Vector2(_size.x / area_amount_x - (area_amount_x - 1) * _street_size.x / area_amount_x, _size.y / randy - (randy - 1) * _street_size.y / randy))
					
					var relocation = Vector2(_size.x / 2 - o * area._area_size.x - (o) * _street_size.x, _size.y / 2 - p * area._area_size.y - (p) * _street_size.y)
					
					# Create ground
					generate_ground(area._area_size, Vector2(-relocation.x + area._area_size.x / 2, -relocation.y + area._area_size.y / 2), ground_arr)
					# Create sidewalk for each area
					generate_sidewalk(Vector2(-relocation.x + area._area_size.x / 2, -relocation.y + area._area_size.y / 2), area._area_size, sidewalk_arr)
					
					# Set property size
					match _skyscraper_type:
						Skyscraper_type.Low:
							_prop_width = 30
							_prop_depth = 30
						Skyscraper_type.Mid:
							_prop_width = 40
							_prop_depth = 40
						Skyscraper_type.High:
							_prop_width = 60
							_prop_depth = 60
					
					# Set amount of buildings within grid
					var amount_x : int = max(1, floori(area._area_size.x / _prop_width))
					var amount_y : int = max(1, floori(area._area_size.y / _prop_depth))
					# Recalculate property size
					_prop_width = area._area_size.x / amount_x
					_prop_depth = area._area_size.y / amount_y
					# Create for every row and column of the block a building
					for i in amount_x:
						for j in amount_y:
							var build : bool = false
							# Build only when building next to road
							if i == 0 or j == 0 or i == amount_x - 1 or j == amount_y - 1:
								build = true
							if build:
								# Building house
								var displacement
								displacement = Vector2(i * (area._area_size.x - _prop_width) / (amount_x - 1), j * (area._area_size.y - _prop_depth) / (amount_y - 1))
								
								var property = properties.instantiate()
								# Checking to fill blank space when needed
								if i == 0 and amount_x > 3:
									if j > 0 and j < amount_y - 1:
										property.position = Vector3(0, 0, 0) - Vector3(relocation.x - _prop_width - displacement.x, _sidewalk_height, relocation.y - _prop_depth / 2 - displacement.y)
										property.initz(Vector2(2 * _prop_width, _prop_depth), _block_type, _skyscraper_type, _house_type, false, false)
									else:
										property.position = Vector3(0, 0, 0) - Vector3(relocation.x - _prop_width / 2 - displacement.x, _sidewalk_height, relocation.y - _prop_depth / 2 - displacement.y)
										property.initz(Vector2(_prop_width, _prop_depth), _block_type, _skyscraper_type, _house_type, false, false)
								elif i == amount_x - 1 and amount_x > 3:
									if j > 0 and j < amount_y - 1:
										property.position = Vector3(0, 0, 0) - Vector3(relocation.x - displacement.x, _sidewalk_height, relocation.y - _prop_depth / 2 - displacement.y)
										property.initz(Vector2(2 * _prop_width, _prop_depth), _block_type, _skyscraper_type, _house_type, false, false)
									else:
										property.position = Vector3(0, 0, 0) - Vector3(relocation.x - _prop_width / 2 - displacement.x, _sidewalk_height, relocation.y - _prop_depth / 2 - displacement.y)
										property.initz(Vector2(_prop_width, _prop_depth), _block_type, _skyscraper_type, _house_type, false, false)
								else:
									property.position = Vector3(0, 0, 0) - Vector3(relocation.x - _prop_width / 2 - displacement.x, _sidewalk_height, relocation.y - _prop_depth / 2 - displacement.y)
									property.initz(Vector2(_prop_width, _prop_depth), _block_type, _skyscraper_type, _house_type, false, false)
								
								# Quick fix for Skyscraper Block, because there should be a stay when the size allows it
								if _block_type == Block_type.Blocks:
									property.position = Vector3(0, 0, 0) - Vector3(relocation.x - _prop_width / 2 - displacement.x, _sidewalk_height, relocation.y - _prop_depth / 2 - displacement.y)
									property.initz(Vector2(_prop_width, _prop_depth), _block_type, _skyscraper_type, _house_type, false, false)
								
								# Generate final meshes
								property.generate_mesh()
								self.add_child(property)
			
			# Combine array meshes
			ground_arr = combine_surfaces(ground_arr)
			sidewalk_arr = combine_surfaces(sidewalk_arr)
			
			var st = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			st.create_from(ground_arr, 0)
			st.generate_normals()
			combined_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
			st = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			st.create_from(sidewalk_arr, 0)
			st.generate_normals()
			combined_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
			
			combined_mesh.surface_set_material(0, _mat_asphalt)
			combined_mesh.surface_set_material(1, _mat_sidewalk)
			
			if area_amount_x > 1 or area_amount_y > 1:
				generate_fill_street(area_amount_x, area_amount_y_colums, combined_mesh)
				if combined_mesh.get_surface_count() > 1:
					combined_mesh.surface_set_material(2, _mat_street)
			
			mesh = combined_mesh
		
		# Generation for type Suburban
		Block_type.Suburban:
			# Block setup
			if _area_density >= -0.3:
				_house_type = House_type.Small
				_min_areal_size = Vector2(50, 50)
			elif _area_density >= -0.6:
				_house_type = House_type.Mid
				_min_areal_size = Vector2(75, 75)
			else:
				_house_type = House_type.Large
				_min_areal_size = Vector2(100, 100)
			
			# Get areal amounts within grid
			var area_amount_x = max(1, floori(_size.x / max(_min_areal_size.x, 1)))
			var area_amount_y = max(1, floori(_size.y / max(_min_areal_size.y, 1)))
			# ArrayMeshes to combine in final mesh
			var ground_arr = ArrayMesh.new()
			var sidewalk_arr = ArrayMesh.new()
			# Array for later generating knots (streets)
			var area_amount_y_colums = []
			var randy
			# Generate for each area the buildings
			for o in area_amount_x:
				if !_grid:
					randy = randi_range(1, area_amount_y)
					area_amount_y_colums.append(randy)
				else:
					randy = area_amount_y
					area_amount_y_colums.append(randy)
				for p in randy:
					var area = Area.new()
					area.set_size(Vector2(_size.x / area_amount_x - (area_amount_x - 1) * _street_size.x / area_amount_x, _size.y / randy - (randy - 1) * _street_size.y / randy))
					
					var relocation = Vector2(_size.x / 2 - o * area._area_size.x - (o) * _street_size.x, _size.y / 2 - p * area._area_size.y - (p) * _street_size.y)
					
					# Create ground
					generate_ground(area._area_size, Vector2(-relocation.x + area._area_size.x / 2, -relocation.y + area._area_size.y / 2), ground_arr)
					# Create sidewalk for each area
					generate_sidewalk(Vector2(-relocation.x + area._area_size.x / 2, -relocation.y + area._area_size.y / 2), area._area_size, sidewalk_arr)
					
					# Area setup
					if area._area_size.x > area._area_size.y:
						match _house_type:
							House_type.Small:
								_prop_width = randf_range(15, 21)
								_prop_depth = randf_range(9, 12)
							House_type.Mid:
								_prop_width = randf_range(24, 36)
								_prop_depth = randf_range(15, 21)
							House_type.Large:
								_prop_width = randf_range(36, 55)
								_prop_depth = randf_range(24, 33)
					else:
						match _house_type:
							House_type.Small:
								_prop_width = randf_range(9, 12)
								_prop_depth = randf_range(15, 21)
							House_type.Mid:
								_prop_width = randf_range(15, 21)
								_prop_depth = randf_range(24, 36)
							House_type.Large:
								_prop_width = randf_range(24, 33)
								_prop_depth = randf_range(36, 55)
					
					# Get amount of properties within area
					var amount_x : int = max(1, floori(area._area_size.x / _prop_width))
					var amount_y : int = max(1, floori(area._area_size.y / _prop_depth))
					# Recalculate property size
					_prop_width = area._area_size.x / amount_x
					_prop_depth = area._area_size.y / amount_y
					# If property width is bigger than depth, change values for correct generation of buildings
					if _prop_width > _prop_depth and amount_x == 2:
						var s_amount_x = amount_x
						_prop_width = _prop_depth
						amount_x = amount_y
						amount_y = s_amount_x
						_prop_width = area._area_size.x / amount_x
						_prop_depth = area._area_size.y / amount_y
					# Building each property
					for i in amount_x:
						for j in amount_y:
							var build : bool = false
							# Build only when building next to road
							if i == 0 or j == 0 or i == amount_x - 1 or j == amount_y - 1:
								build = true
							if build:
								# Building house
								var displacement : Vector2
								
								# Set displacement for property within area
								if i == 0 and j > 0 and j < amount_y - 1:
									displacement = Vector2(- _prop_width + area._area_size.x / 4, j * (area._area_size.y - _prop_depth) / (amount_y - 1))
								elif i == amount_x - 1 and j > 0 and j < amount_y - 1:
									displacement = Vector2(3 * area._area_size.x / 4 , j * (area._area_size.y - _prop_depth) / (amount_y - 1))
								elif amount_y == 1:
									displacement = Vector2(i * (area._area_size.x - _prop_width) / (amount_x - 1), 0)
								else:
									displacement = Vector2(i * (area._area_size.x - _prop_width) / (amount_x - 1), j * (area._area_size.y - _prop_depth) / (amount_y - 1))
								
								# Generate additional fences based on grid location
								var fence_x : bool = false
								var fence_y : bool = false
								if i + 1 >= amount_x:
									fence_x = true
								if j + 1 >= amount_y:
									fence_y = true
								# Generate property
								var property = properties.instantiate()
								var property2 # Only needed if property can be split
								# Checking to fill blank space when needed
								if i == 0 and amount_x > 2:
									if j > 0 and j < amount_y - 1:
										# When property is to big with fill, it gets divided into two
										if (amount_x * _prop_width / 2) >= 1 * _prop_depth and _prop_depth / 2 >= 0.85 * _prop_width:
											property.initz(Vector2(amount_x * _prop_width / 2, _prop_depth / 2), _block_type, _skyscraper_type, _house_type, fence_x, fence_y)
											property.position = Vector3(0, 0, 0) - Vector3(relocation.x - _prop_width - displacement.x, _sidewalk_height, relocation.y - _prop_depth / 2 - displacement.y + property._size.y / 2)
											property2 = properties.instantiate()
											property2.initz(Vector2(amount_x * _prop_width / 2, _prop_depth / 2), _block_type, _skyscraper_type, _house_type, fence_x, fence_y)
											property2.position = Vector3(0, 0, 0) - Vector3(relocation.x - _prop_width - displacement.x, _sidewalk_height, relocation.y - _prop_depth / 2 - displacement.y - property2._size.y / 2)
										else:
											property.initz(Vector2(amount_x * _prop_width / 2, _prop_depth), _block_type, _skyscraper_type, _house_type, fence_x, fence_y)
											property.position = Vector3(0, 0, 0) - Vector3(relocation.x - _prop_width - displacement.x, _sidewalk_height, relocation.y - _prop_depth / 2 - displacement.y)
									else:
										property.initz(Vector2(_prop_width, _prop_depth), _block_type, _skyscraper_type, _house_type, fence_x, fence_y)
										property.position = Vector3(0, 0, 0) - Vector3(relocation.x - _prop_width / 2 - displacement.x, _sidewalk_height, relocation.y - _prop_depth / 2 - displacement.y)
								elif i == amount_x - 1 and amount_x > 2:
									if j > 0 and j < amount_y - 1:
										# When property is to big with fill, it gets divided into two
										if (amount_x * _prop_width / 2) >= 0.85 * _prop_depth and _prop_depth / 2 >= 0.85 * _prop_width:
											property.initz(Vector2(amount_x * _prop_width / 2, _prop_depth / 2), _block_type, _skyscraper_type, _house_type, fence_x, fence_y)
											property.position = Vector3(0, 0, 0) - Vector3(relocation.x - displacement.x, _sidewalk_height, relocation.y - _prop_depth / 2 - displacement.y + property._size.y / 2)
											property2 = properties.instantiate()
											property2.initz(Vector2(amount_x * _prop_width / 2, _prop_depth / 2), _block_type, _skyscraper_type, _house_type, fence_x, fence_y)
											property2.position = Vector3(0, 0, 0) - Vector3(relocation.x - displacement.x, _sidewalk_height, relocation.y - _prop_depth / 2 - displacement.y - property2._size.y / 2)
										else:
											property.initz(Vector2(amount_x * _prop_width / 2, _prop_depth), _block_type, _skyscraper_type, _house_type, fence_x, fence_y)
											property.position = Vector3(0, 0, 0) - Vector3(relocation.x - displacement.x, _sidewalk_height, relocation.y - _prop_depth / 2 - displacement.y)
									else:
										property.initz(Vector2(_prop_width, _prop_depth), _block_type, _skyscraper_type, _house_type, fence_x, fence_y)
										property.position = Vector3(0, 0, 0) - Vector3(relocation.x - _prop_width / 2 - displacement.x, _sidewalk_height, relocation.y - _prop_depth / 2 - displacement.y)
								else:
									property.initz(Vector2(_prop_width, _prop_depth), _block_type, _skyscraper_type, _house_type, fence_x, fence_y)
									property.position = Vector3(0, 0, 0) - Vector3(relocation.x - _prop_width / 2 - displacement.x, _sidewalk_height, relocation.y - _prop_depth / 2 - displacement.y)
								
								# Generate final meshes
								property.generate_mesh()
								self.add_child(property)
								if property2:
									property2.generate_mesh()
									self.add_child(property2)
								
			# Combine array meshes for ground and sidewalk
			ground_arr = combine_surfaces(ground_arr)
			sidewalk_arr = combine_surfaces(sidewalk_arr)
			
			# Add groind and sidwalk surface to combined_mesh
			var st = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			st.create_from(ground_arr, 0)
			st.generate_normals()
			combined_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
			st = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			st.create_from(sidewalk_arr, 0)
			st.generate_normals()
			combined_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
			
			# Set materials for ground and sidewalk
			combined_mesh.surface_set_material(0, _mat_grass)
			combined_mesh.surface_set_material(1, _mat_sidewalk)
			
			# Generate streets between the areas
			if area_amount_x > 1 or area_amount_y > 1:
				generate_fill_street(area_amount_x, area_amount_y_colums, combined_mesh)
				combined_mesh.surface_set_material(2, _mat_street)
			
			# Set mesh
			mesh = combined_mesh
		
		Block_type.Industry:
			pass

func generate_ground(area_size: Vector2, displacement: Vector2, combined_mesh: ArrayMesh):
	# Create ground plane
	var ground_mesh = PlaneMesh.new()
	ground_mesh.size = Vector2(area_size.x, area_size.y)
	# Surfacetool plane
	var st_ground = SurfaceTool.new()
	st_ground.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_ground.create_from(ground_mesh, 0)
	
	var mesh_array = st_ground.commit_to_arrays()
	var vertices = mesh_array[ArrayMesh.ARRAY_VERTEX]
	# Modify vertex location
	for n in range(vertices.size()):
		vertices[n].x += displacement.x
		vertices[n].y += _sidewalk_height
		vertices[n].z += displacement.y
	mesh_array[ArrayMesh.ARRAY_VERTEX] = vertices
	
	# Generate normals
	st_ground.generate_normals()
	
	# Add ground to ArrayMesh
	combined_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_array)

func generate_sidewalk(displacement: Vector2, area_size: Vector2, combined_mesh: ArrayMesh):
	var local_displacement
	var local_size
	var sidewalks_mesh = ArrayMesh.new()
	
	for i in 4:
		if i == 0:
			local_displacement = Vector2(0, - area_size.y / 2 - _sidewalk_width / 2)
			local_size = Vector3(area_size.x, _sidewalk_height, _sidewalk_width)
		elif i == 1:
			local_displacement = Vector2(0, area_size.y / 2 + _sidewalk_width / 2)
			local_size = Vector3(area_size.x, _sidewalk_height, _sidewalk_width)
		elif i == 2:
			local_displacement = Vector2(- area_size.x / 2 - _sidewalk_width / 2, 0)
			local_size = Vector3(_sidewalk_width, _sidewalk_height, area_size.y + 2 * _sidewalk_width)
		else:
			local_displacement = Vector2(area_size.x / 2 + _sidewalk_width / 2, 0)
			local_size = Vector3(_sidewalk_width, _sidewalk_height, area_size.y + 2 * _sidewalk_width)
		
		var box_mesh = BoxMesh.new()
		box_mesh.size = local_size
		var st_sidewalk = SurfaceTool.new()
		st_sidewalk.begin(Mesh.PRIMITIVE_TRIANGLES)
		st_sidewalk.create_from(box_mesh, 0)
		
		var mesh_array = st_sidewalk.commit_to_arrays()
		var vertices = mesh_array[ArrayMesh.ARRAY_VERTEX]
		# Modify vertex location
		for n in range(vertices.size()):
			vertices[n].x += displacement.x + local_displacement.x
			vertices[n].y += _sidewalk_height / 2
			vertices[n].z += displacement.y + local_displacement.y
		mesh_array[ArrayMesh.ARRAY_VERTEX] = vertices
		
		# Generate normals
		st_sidewalk.generate_normals()
		
		# Add ground to ArrayMesh
		sidewalks_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_array)
	
	sidewalks_mesh = combine_surfaces(sidewalks_mesh)
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.create_from(sidewalks_mesh, 0)
	st.generate_normals()
	
	combined_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

func generate_fill_street(area_amount_x: float, area_amount_y_colums: Array, combined_mesh: ArrayMesh):
	# Setting up y values in arrays to generate knots for streets from it
	var knot_valueY = []
	
	for i in area_amount_x + 1:
		var value_arr = [] # Current street colum
		if i == 0: # First colum
			for j in area_amount_y_colums[0] + 1:
				value_arr.append(-_size.y / 2 - _street_size.y / 2 + j * (_size.y + _street_size.y) / area_amount_y_colums[0])
			knot_valueY.append(value_arr)
		elif i == area_amount_x: # Last colum
			for j in area_amount_y_colums[area_amount_y_colums.size() - 1] + 1:
				value_arr.append(-_size.y / 2 - _street_size.y / 2 + j * (_size.y + _street_size.y) / area_amount_y_colums[area_amount_y_colums.size() - 1])
			knot_valueY.append(value_arr)
		elif area_amount_y_colums[i - 1] == area_amount_y_colums[i]: # If amount of areas in y is equal before and after street, they share eachothers knot
			for j in area_amount_y_colums[i - 1] + 1:
				value_arr.append(-_size.y / 2 - _street_size.y / 2 + j * (_size.y + _street_size.y) / area_amount_y_colums[i - 1])
			knot_valueY.append(value_arr)
		else: # Procedure to make combined colum of knots based on shared knots and individual knots around each area neighbouring the street to generate
			# Setting up y values for each area neighbouring the street colum
			var vFew = []
			var vMany = []
			if area_amount_y_colums[i - 1] < area_amount_y_colums[i]:
				for j in area_amount_y_colums[i - 1] + 1:
					vFew.append(-_size.y / 2 - _street_size.y / 2 + j * (_size.y + _street_size.y) / area_amount_y_colums[i - 1])
				for j in area_amount_y_colums[i] + 1:
					vMany.append(-_size.y / 2 - _street_size.y / 2 + j * (_size.y + _street_size.y) / area_amount_y_colums[i])
			else:
				for j in area_amount_y_colums[i - 1] + 1:
					vMany.append(-_size.y / 2 - _street_size.y / 2 + j * (_size.y + _street_size.y) / area_amount_y_colums[i - 1])
				for j in area_amount_y_colums[i] + 1:
					vFew.append(-_size.y / 2 - _street_size.y / 2 + j * (_size.y + _street_size.y) / area_amount_y_colums[i])
			# Combine arrays without dublication
			var abort_index = 0
			for j in vFew.size():
				value_arr.append(vFew[j])
				if j != vFew.size() - 1:
					for n in range(abort_index, vMany.size()):
						if !value_arr.has(vMany[n]) and vMany[n] < vFew[j + 1]:
							value_arr.append(vMany[n])
						if vMany[n] >= vFew[j + 1]:
							abort_index = n
							break
			if !value_arr.has(vFew[vFew.size() - 1]):
				value_arr.append(vFew[vFew.size() - 1])
			# Append value array to get values when creating knots
			knot_valueY.append(value_arr)
	
	# Create "abstract" knots
	var street_mesh = ArrayMesh.new()
	var _knot_colums = []
	
	# If there is ony one area column
	if knot_valueY.size() == 2:
		for i in knot_valueY.size() + 1:
			_knot_colums.append([])
			
			if i == 0:
				for j in knot_valueY[0].size():
					var knot = knots.instantiate()
					knot.init(Vector3(-_size.x / 2 - _street_size.x / 2 + i * (_size.x + _street_size.x) / (knot_valueY.size()), 0, knot_valueY[0][j]), Vector3(_street_size.x, 0, _street_size.y))
					_knot_colums[i].append(knot)
			elif i == 1:
				for j in knot_valueY[0].size():
					var knot = knots.instantiate()
					knot.init(Vector3(-_size.x / 2 - _street_size.x / 2 + i * (_size.x + _street_size.x) / (knot_valueY.size()), 0, knot_valueY[0][j]), Vector3(_street_size.x, 0, _street_size.y))
					_knot_colums[i].append(knot)
			elif i == 2:
				for j in knot_valueY[1].size():
					var knot = knots.instantiate()
					knot.init(Vector3(-_size.x / 2 - _street_size.x / 2 + i * (_size.x + _street_size.x) / (knot_valueY.size()), 0, knot_valueY[1][j]), Vector3(_street_size.x, 0, _street_size.y))
					_knot_colums[i].append(knot)
	# There is more than one area column
	else:
		for i in knot_valueY.size():
			_knot_colums.append([])
			
			# If there is a street between only two areas -> generate a additional knot to generate a street
			if knot_valueY[i].size() == 2:
				for j in knot_valueY[i].size() + 1:
					var knot = knots.instantiate()
					knot.init(Vector3(-_size.x / 2 - _street_size.x / 2 + i * (_size.x + _street_size.x) / (knot_valueY.size() - 1), 0, - (_size.y + _street_size.y) / 2 + j * (_size.y + _street_size.y) / 2), Vector3(_street_size.x, 0, _street_size.y))
					_knot_colums[i].append(knot)
			else:
				for j in knot_valueY[i].size():
					var knot = knots.instantiate()
					knot.init(Vector3(-_size.x / 2 - _street_size.x / 2 + i * (_size.x + _street_size.x) / (knot_valueY.size() - 1), 0, knot_valueY[i][j]), Vector3(_street_size.x, 0, _street_size.y))
					_knot_colums[i].append(knot)
	
	# Floor y values for better comparison of same heights of knots
	for i in knot_valueY.size():
		for j in knot_valueY[i].size():
			knot_valueY[i][j] = roundi(knot_valueY[i][j])
			
	# Setup connections and generate meshes
	for i in range(_knot_colums.size()):
		for j in range(_knot_colums[i].size()):
			# Setup vertical connections
			if knot_valueY.size() > 2:
				if j == 0:
					_knot_colums[i][j].set_con_s(_knot_colums[i][j + 1])
				elif j == _knot_colums[i].size() - 1:
					_knot_colums[i][j].set_con_n(_knot_colums[i][j - 1])
				else:
					_knot_colums[i][j].set_con_n(_knot_colums[i][j - 1])
					if abs(_knot_colums[i][j + 1]._location.z - _knot_colums[i][j]._location.z) > _street_size.y:
						_knot_colums[i][j].set_con_s(_knot_colums[i][j + 1])
				
				# Setup full connection to big street
				if i == 1:
					_knot_colums[i][j].set_full_con_w(true)
					if _knot_colums.size() < 4:
						_knot_colums[i][j].set_full_con_e(true)
				elif i == _knot_colums.size() - 2:
					_knot_colums[i][j].set_full_con_e(true)
				
				if j == 1:
					_knot_colums[i][j].set_full_con_n(true)
					if _knot_colums[i].size() < 4:
						_knot_colums[i][j].set_full_con_s(true)
				elif j == _knot_colums[i].size() - 2:
					_knot_colums[i][j].set_full_con_s(true)
			
			# Setup horizontal connections
			if knot_valueY.size() == 2:
				for n in _knot_colums.size() - 1:
					_knot_colums[n][j].set_con_e(_knot_colums[n + 1][j])
					_knot_colums[n + 1][j].set_con_w(_knot_colums[n][j])
					if n == 1:
						_knot_colums[n][j].set_full_con_e(true)
						_knot_colums[n][j].set_full_con_w(true)
			else:
				if i != _knot_colums.size() - 1:
					var id = knot_valueY[i + 1].find(roundi(_knot_colums[i][j]._location.z))
					if id != -1:
						for n in area_amount_y_colums[i] + 1:
							if int(n * (_size.y + _street_size.y) / area_amount_y_colums[i]) == int(_knot_colums[i][j]._location.z + (_size.y + _street_size.y) / 2) and area_amount_y_colums[i] != 1:
								_knot_colums[i][j].set_con_e(_knot_colums[i + 1][id])
								_knot_colums[i + 1][id].set_con_w(_knot_colums[i][j])
			
			if i != 0 and i != _knot_colums.size() - 1:
				if j != 0 and j != _knot_colums[i].size() - 1:
					_knot_colums[i][j].generate_mesh(street_mesh)
					if street_mesh.get_surface_count() >= 50:
						street_mesh = combine_surfaces(street_mesh)
	
	street_mesh = combine_surfaces(street_mesh)
	
	# Procedure to add single surface to combined_mesh
	if street_mesh.get_surface_count() > 0: # If there is no surface there is nothing to add
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.create_from(street_mesh, 0)
		st.generate_normals()
		combined_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

# Combines surfaces within a ArraMesh
func combine_surfaces(original_mesh: ArrayMesh):
	if original_mesh.get_surface_count() <= 1:
		return original_mesh
	else:
		var combined_mesh = ArrayMesh.new()
		var st = SurfaceTool.new()
		
		# Begin creating the combined surface with triangles as the primitive type
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		# Iterate through each surface in the original mesh
		for surface in range(original_mesh.get_surface_count()):
			# Append the surface from the original mesh to the SurfaceTool with an identity transform
			st.append_from(original_mesh, surface, Transform3D())
		
		# Commit the combined arrays to the new mesh
		st.generate_normals()
		combined_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
		
		return combined_mesh
