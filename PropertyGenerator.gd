@tool
extends MeshInstance3D

# Enums
enum Block_type { Blocks, Suburban, Industry }
enum Skyscraper_type { Low, Mid, High }
enum House_type { Small, Mid, Large }

# Materials
var _mat_building = preload("res://Materials/M_Building.tres")
var _mat_fence = preload("res://Materials/M_Fence.tres")

# Global variables
var _size = Vector2(20.0,20.0)
var _block_type = Block_type.Suburban
var _skyscraper_type = Skyscraper_type.Low
var _house_type = House_type.Small
var _fence_height : float = 1
var _last_x = false
var _last_y = false

@export var rebuild: bool:
	set(value):
		generate_mesh()

# Setup variables
func initz(size: Vector2, block_type: Block_type, skyscraper_type: Skyscraper_type, house_type: House_type, last_x: bool, last_y: bool):
	_size = size
	_block_type = block_type
	_skyscraper_type = skyscraper_type
	_house_type = house_type
	_last_x = last_x
	_last_y = last_y

# Generates mesh for property
func generate_mesh():
	var combined_mesh = ArrayMesh.new()
	# Based on block type
	match _block_type:
		Block_type.Blocks:
			var single = false
			var width
			var depth
			var height
			# Setting up dimensions for building
			match _skyscraper_type:
				Skyscraper_type.Low:
					var maxx # Renaming because max() function exists
					if single:
						maxx = _size.x - randi_range(5, 15)
					else:
						maxx = 30
					width = randi_range(20, maxx)
					depth = randi_range(20, maxx)
					height = randi_range(20, 80)
				Skyscraper_type.Mid:
					var maxx # Renaming because max() function exists
					if single:
						maxx = _size.x - randi_range(5, 15)
					else:
						maxx = 40
					width = randi_range(25, maxx)
					depth = randi_range(25, maxx)
					height = randi_range(120, 200)
				Skyscraper_type.High:
					var maxx # Renaming because max() function exists
					if single:
						maxx = _size.x - randi_range(5, 15)
					else:
						maxx = 60
					width = randi_range(30, maxx)
					depth = randi_range(30, maxx)
					height = randi_range(300, 400)
			
			# Create BoxMesh
			var building_mesh = BoxMesh.new()
			building_mesh.size = Vector3(width, height, depth)
			# SurfaceTool for building
			var st_building = SurfaceTool.new()
			st_building.begin(Mesh.PRIMITIVE_TRIANGLES)
			st_building.create_from(building_mesh, 0)
			# Modify vertex location - to it's correct place in grid
			var mesh_array = st_building.commit_to_arrays()
			var vertices = mesh_array[ArrayMesh.ARRAY_VERTEX]
			for n in range(vertices.size()):
				vertices[n].x += 0
				vertices[n].y += height / 2
				vertices[n].z += 0
			mesh_array[ArrayMesh.ARRAY_VERTEX] = vertices
			
			# Generate normals
			st_building.generate_normals()
			
			# Add mesh as surface to ArrayMesh
			combined_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_array)
			
			var y = height / 7
			var x = width / 10
			
			# Set material
			var mat = _mat_building.duplicate()
			var string = "res://Textures/facade_" + str(randi_range(1, 12)) + ".png"
			mat.set_shader_parameter("texture_wall", load(string))
			mat.set_shader_parameter("mult_uv", Vector2(x, y))
			combined_mesh.surface_set_material(0, mat)
		
		Block_type.Suburban:
			var width
			var depth
			var height = randi_range(10, 30)
			# Setting up dimensions
			match _house_type:
				House_type.Small:
					width = randf_range(6, 9)
					depth = randf_range(6, 9)
					height = randf_range(4, 5.5)
				House_type.Mid:
					width = randf_range(9, 15)
					depth = randf_range(9, 15)
					height = randf_range(7, 8.5)
				House_type.Large:
					width = randf_range(15, 21)
					depth = randf_range(15, 21)
					height = randf_range(10, 11.5)
			# Create BoxMesh
			var building_mesh = BoxMesh.new()
			building_mesh.size = Vector3(width, height, depth)
			# Create SurfaceTool
			var st_building = SurfaceTool.new()
			st_building.begin(Mesh.PRIMITIVE_TRIANGLES)
			st_building.create_from(building_mesh, 0)
			# Modify vertex location - to it's correct place in grid
			var mesh_array = st_building.commit_to_arrays()
			var vertices = mesh_array[ArrayMesh.ARRAY_VERTEX]
			var house_displacement = Vector2(randf_range(- (_size.x - width) / 2, (_size.x - width) / 2), randf_range(- (_size.y - depth) / 2, (_size.y - depth) / 2))
			for n in range(vertices.size()):
				vertices[n].x += house_displacement.x
				vertices[n].y += height / 2
				vertices[n].z += house_displacement.y
			mesh_array[ArrayMesh.ARRAY_VERTEX] = vertices
			
			# Generate normals
			st_building.generate_normals()
			
			# Add mesh as surface to ArrayMesh
			combined_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_array)
			
			# Setup fences
			var fence_combined_mesh = ArrayMesh.new()
			# Building two fences (left and top)
			for u in 2:
				# Building fence
				var fence_size : Vector3
				if u == 1:
					fence_size = Vector3(0.2, _fence_height, _size.y)
				else:
					fence_size = Vector3(_size.x, _fence_height, 0.2)
				var fence_displacement
				if u == 1:
					fence_displacement = Vector2(-_size.x / 2, 0)
				else:
					fence_displacement = Vector2(0, -_size.y / 2)
				create_fence(fence_size, fence_displacement, fence_combined_mesh)
			# Building fence right
			if _last_x:
				# Fence setup
				var fence_displacement = Vector2(_size.x / 2, 0)
				var fence_size = Vector3(0.2, _fence_height, _size.y)
				# Create fence
				create_fence(fence_size, fence_displacement, fence_combined_mesh)
			# Building fence bottom
			if _last_y:
				# Fence setup
				var fence_displacement = Vector2(0, _size.y / 2)
				var fence_size = Vector3(_size.x, _fence_height, 0.2)
				# Create fence
				create_fence(fence_size, fence_displacement, fence_combined_mesh)
			
			# Combine fence surfaces
			fence_combined_mesh = combine_surfaces(fence_combined_mesh)
			# Generate surface tool and add surface to combined mesh
			var surfacetool = SurfaceTool.new()
			surfacetool.begin(Mesh.PRIMITIVE_TRIANGLES)
			surfacetool.create_from(fence_combined_mesh, 0)
			surfacetool.generate_normals()
			combined_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surfacetool.commit_to_arrays())
			
			# Set material
			var mat = _mat_building.duplicate()
			var string = "res://Textures/home_" + str(randi_range(1, 5)) + ".png"
			mat.set_shader_parameter("texture_wall", load(string))
			mat.set_shader_parameter("mult_uv", Vector2(2.0, 2.0))
			combined_mesh.surface_set_material(0, mat)
			combined_mesh.surface_set_material(1, _mat_fence)
	
	# Set mesh
	mesh = combined_mesh

# Create fence
func create_fence(fence_size: Vector3, fence_displacement: Vector2, fence_combined_mesh: ArrayMesh):
	# Create Boxmesh
	var fence_mesh = BoxMesh.new()
	fence_mesh.size = fence_size
	# Fence surfaceTool
	var st_fence = SurfaceTool.new()
	st_fence.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_fence.create_from(fence_mesh, 0)
	
	# Modify vertex location
	var mesh_array = st_fence.commit_to_arrays()
	var vertices = mesh_array[ArrayMesh.ARRAY_VERTEX]
	for n in range(vertices.size()):
		vertices[n].x += fence_displacement.x
		vertices[n].y += _fence_height / 2
		vertices[n].z += fence_displacement.y
	mesh_array[ArrayMesh.ARRAY_VERTEX] = vertices
	
	# Generate normals
	st_fence.generate_normals()
	
	# Add mesh as surface to ArrayMesh
	fence_combined_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_array)

# Combines surfaces within an ArrayMesh
func combine_surfaces(original_mesh: ArrayMesh):
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
