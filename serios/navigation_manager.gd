extends Node

# Holds data passed between scenes (e.g. {"mode": "Due"})
var payload: Dictionary = {}

func go_to(scene_path: String, data: Dictionary = {}) -> void:
	payload = data
	get_tree().change_scene_to_file(scene_path)
