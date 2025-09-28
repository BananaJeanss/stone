extends Node

const SAVE_FILE := "user://pb.save"
var best_times: Dictionary = {}  # { "stage1": 12.345, "stage2": 45.678 }

func _ready() -> void:
	best_times = load_pb()

func save_pb(stage: String, time: float) -> void:
	best_times[stage] = time
	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	file.store_var(best_times)

func load_pb() -> Dictionary:
	if FileAccess.file_exists(SAVE_FILE):
		var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
		return file.get_var()
	return {}
