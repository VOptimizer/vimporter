@tool
extends EditorSceneFormatImporter

static var SUPPORTED_EXTENSIONS : PackedStringArray = ["vox", "gox", "qb", "qef", "qbt", "qbcl", "kenshape"]

func _get_extensions() -> PackedStringArray:
	return SUPPORTED_EXTENSIONS
	
func _get_import_flags() -> int:
	return IMPORT_SCENE
	
func _import_scene(path: String, flags: int, options: Dictionary) -> Object:
	var result : Node = null
	if options.has("nodes/root_type") && !options["nodes/root_type"].is_empty():
		result = ClassDB.instantiate(options["nodes/root_type"])
	else:
		result = Node3D.new()
		result.owner = null
	
	var loader : VLoader = VLoader.new()
	if loader.load(path) == OK:
		var tree : VSceneNode = loader.get_scene_tree()
		if tree:
			var mesher : VMesher = VMesher.new()
			
			if(options.has("vcore/mesher")):
				mesher.mesher_type = options["vcore/mesher"]
			
			var scene : Array = mesher.generate_scene(tree, false)
			if !scene.is_empty():
				# Keep track of possible duplicated names.
				var nameCounter:  Dictionary = {}
				var parents : Array = []
				var animation : Animation = null
				var animation_length : int = 0
				parents.push_back(result)
				
				for m in scene:
					var mesh := ImporterMeshInstance3D.new()
					mesh.mesh = _convert_to_importer_mesh(m.mesh)
					
					# Generates a unique name for the meshinstance
					var name := path.get_basename().get_file()
					if !m.name.is_empty():
						name = m.name
					
					if !animation:
						# Check and track the name.
						if nameCounter.has(name):
							var oldname := name
							name += str(nameCounter[name])
							nameCounter[oldname] += 1
						else:
							nameCounter[name] = 1
					
					# Did we deal with an animation?
					if m.frameTime > 0:
						if !animation:
							var node := Node3D.new()
							node.name = name
							if !parents.is_empty():
								parents.back().add_child(node)
								node.owner = parents.back()

							parents.push_back(node)
							
							animation = Animation.new()
							mesh.visible = true
						else:
							mesh.visible = false
						
						mesh.name = name + "_" + str(m.frameTime)
						var track_id := animation.add_track(Animation.TYPE_VALUE)
						animation.track_set_path(track_id, "./" + mesh.name + ":visible")
						
						if animation_length != 0:
							animation.track_insert_key(track_id, 0, false)
						
						animation.track_insert_key(track_id, animation_length / 1000.0, true)
						animation.track_insert_key(track_id, (animation_length + m.frameTime) / 1000.0, false)
						animation.track_set_interpolation_type(track_id, Animation.INTERPOLATION_NEAREST)
						
						animation_length += m.frameTime
					else:
						if animation:
							var node : Node3D = parents.pop_back()
							var player : AnimationPlayer = _create_player(animation, animation_length)
							player.name = node.name + "_Anim"
							node.add_child(player)
							player.owner = result
							
							animation = null
							animation_length = 0
						
						mesh.name = name
					mesh.transform = m.transform
					
					#if scene.size() == 1:
						#result = mesh
						#result.owner = null
					#else:
					parents.back().add_child(mesh)
					mesh.owner = result
	
				if animation:
					var player : AnimationPlayer = _create_player(animation, animation_length)
					player.name = parents.back().name + "_Anim"
					parents.back().add_child(player)
					player.owner = result
	
	# Has the user set a name for the root node?
	if result && options.has("nodes/root_name"):
		result.name = options["nodes/root_name"]
	
	# We need a name.
	if result.name.is_empty():
		result.name = path.get_basename().get_file()
		
	return result

func _create_player(animation : Animation, animation_length : int) -> AnimationPlayer:
	var player : AnimationPlayer = AnimationPlayer.new()
	animation.length = animation_length / 1000.0
	animation.loop_mode = Animation.LOOP_LINEAR

	var lib : AnimationLibrary = AnimationLibrary.new()
	lib.add_animation("Animation", animation)
	player.add_animation_library("Animation", lib)
	player.play("Animation/Animation")
	
	return player

func _convert_to_importer_mesh(mesh : ArrayMesh) -> ImporterMesh:
	var result : ImporterMesh = ImporterMesh.new()
		
	for i in mesh.get_surface_count():
		var mat : VMaterial = mesh.surface_get_material(i)
		var arrays : Array = mesh.surface_get_arrays(i)
		
		# I don't know why, but the importer recognizes the wrong winding order of
		# vcore and corrects the indices? So the normals are flipped.
		# To fix this I need to flip the normals here.
		for j in arrays[ArrayMesh.ARRAY_NORMAL].size():
			arrays[ArrayMesh.ARRAY_NORMAL][j] *= -Vector3.ONE
		
		result.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays)
		result.set_surface_material(i, mat.to_standard_material_3d())
	
	return result
