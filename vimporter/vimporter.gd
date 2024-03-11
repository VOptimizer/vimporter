@tool
extends EditorPlugin

const IMPORTER = preload("res://addons/vimporter/EditorSceneFormatImporterVCore.gd")
const POST_IMPORTER = preload("res://addons/vimporter/EditorScenePostImportPluginVCore.gd")
var _Importer = IMPORTER.new()
var _PostImporter = POST_IMPORTER.new()

func _enter_tree() -> void:
	add_scene_post_import_plugin(_PostImporter)
	add_scene_format_importer_plugin(_Importer)

func _exit_tree() -> void:
	remove_scene_format_importer_plugin(_Importer)
	remove_scene_post_import_plugin(_PostImporter)
