@tool
extends EditorScenePostImportPlugin

const IMPORTER = preload("res://addons/vimporter/EditorSceneFormatImporterVCore.gd")

func _get_import_options(path: String) -> void:
	if IMPORTER.SUPPORTED_EXTENSIONS.find(path.get_extension()) != -1:
		add_import_option_advanced(TYPE_INT, "vcore/mesher", VMesher.GREEDY, PROPERTY_HINT_ENUM, "SIMPLE,GREEDY,MARCHING_CUBES,GREEDY_CHUNKED,GREEDY_TEXTURED")

func _get_option_visibility(path: String, for_animation: bool, option: String) -> Variant:
	if IMPORTER.SUPPORTED_EXTENSIONS.find(path.get_extension()) != -1:
		if option.begins_with("gltf") || option.begins_with("skins") || option.begins_with("animation") ||  option.begins_with("meshes"):
			return false
	
	return true

func _post_process(scene: Node) -> void:
	for i in scene.get_child_count():
		_post_process(scene.get_child(i))
		
	# I don't know why, but godot throws away the visible flag.
	if (scene is MeshInstance3D) || (scene is ImporterMeshInstance3D):
		var timeSplit := scene.name.rsplit("_", false, 1)
		if timeSplit.size() == 2:
			if timeSplit[1].is_valid_int() && (scene.get_parent() is Node3D):
				(scene as Node3D).visible = scene.get_index() == 0
