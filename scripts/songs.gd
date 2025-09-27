extends AudioStreamPlayer

const dirname := "res://music/"

var files: PackedStringArray = PackedStringArray()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	var all_files: PackedStringArray = DirAccess.get_files_at(dirname)
	for f in all_files:
		if not f.to_lower().ends_with(".import"):
			files.append(f)

	_rng.randomize()
	randomSong()


func randomSong() -> void:
	if files.size() == 0:
		print("Warning: No playable files found in %s" % dirname)
		return

	var idx: int = _rng.randi_range(0, files.size() - 1)
	var randomSo: String = files[idx]   # <--- explicit type
	print("Playing: %s" % randomSo)
	stream = load(dirname + randomSo)
	playing = true
	await finished


func _on_finished() -> void:
	randomSong()
