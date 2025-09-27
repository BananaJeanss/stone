extends Node2D

@onready var timelabel = $UI/TimeL

const timeprefix = "Time: "

var elapsed_time := 0.0  # time in seconds
var isCounting = true

func _process(delta: float) -> void:
	# Add the time since last frame
	if isCounting:
		elapsed_time += delta

		# Split into minutes, seconds, milliseconds
		var minutes = int(elapsed_time / 60)
		var seconds = int(elapsed_time) % 60
		var milliseconds = int((elapsed_time - int(elapsed_time)) * 1000)

		# Format string like 0:00.000
		var formatted_time = "%d:%02d.%03d" % [minutes, seconds, milliseconds]

		# Update the label
		timelabel.text = timeprefix + formatted_time


func _on_endpoint_body_entered(_body: Node2D) -> void:
	if _body is CharacterBody2D:
		isCounting = false
