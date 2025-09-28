extends Label

func _ready() -> void:
	var stage_name = get_parent().name
	print(stage_name)
	var pb = TimerManager.best_times.get(stage_name, INF)

	if pb == INF:
		text = ""
	else:
		text = format_time(pb)

func format_time(time: float) -> String:
	var minutes = int(time / 60)
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 1000)
	return "%d:%02d.%03d" % [minutes, seconds, milliseconds]
