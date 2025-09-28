extends Node2D

@onready var timelabel: Label = $UI/TimeL

const SAVE_FILE := "user://pb.save"
const TIME_PREFIX := ""

var elapsed_time: float = 0.0
var is_counting: bool = true
var formatted_time: String = ""
var best_time: float = INF  # stores PB as total seconds

@onready var escProgBar: ProgressBar = $UI/ProgressBar
# (Kept your Timer reference in case you want it for something else)
@onready var EscStep: Timer = $UI/ProgressBar/escStep

# ESC hold handling
const ESC_HOLD_DURATION := 2.0   # seconds required to trigger the action
const ESC_STEP := 0.1            # visual step increment for the progressbar (seconds)

var esc_holding: bool = false
var esc_hold_time: float = 0.0
var esc_triggered: bool = false

func _ready() -> void:
	# configure progressbar so it represents seconds (0..ESC_HOLD_DURATION)
	escProgBar.min_value = 0.0
	escProgBar.max_value = ESC_HOLD_DURATION
	escProgBar.step = ESC_STEP
	escProgBar.visible = false
	escProgBar.set_value_no_signal(0.0)

func _process(delta: float) -> void:
	if is_counting:
		elapsed_time += delta
		formatted_time = format_time(elapsed_time)
		timelabel.text = TIME_PREFIX + formatted_time

	# ESC hold logic (works every frame)
	if Input.is_key_pressed(KEY_ESCAPE):
		# start/continue holding
		esc_holding = true
		esc_hold_time += delta

		# Quantize to step so progressbar "steps"
		var display_value: float = floor(esc_hold_time / ESC_STEP) * ESC_STEP
		if display_value > ESC_HOLD_DURATION:
			display_value = ESC_HOLD_DURATION
		escProgBar.set_value_no_signal(display_value)
		escProgBar.visible = true

		# Trigger once when we reach the required hold time
		if esc_hold_time >= ESC_HOLD_DURATION and not esc_triggered:
			esc_triggered = true
			_on_esc_hold_complete()
	else:
		# released -> reset everything and hide progress bar
		if esc_holding or esc_hold_time > 0.0:
			esc_holding = false
			esc_hold_time = 0.0
			esc_triggered = false
			escProgBar.set_value_no_signal(0.0)
			escProgBar.visible = false


func _on_esc_hold_complete() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func format_time(time: float) -> String:
	var minutes = int(time / 60)
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 1000)
	return "%d:%02d.%03d" % [minutes, seconds, milliseconds]
	
func _on_endpoint_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		is_counting = false
		var stage_name = "stage1"
		var pbt = format_time(TimerManager.best_times.get(stage_name, INF))
		$Passed/ColorRect/Time.text = "Time: " + formatted_time
		$Passed/ColorRect/PBTime.text = "Personal Best: " + pbt
		$Passed.visible = true

		

		if elapsed_time < TimerManager.best_times.get(stage_name, INF):
			TimerManager.save_pb(stage_name, elapsed_time)

		print("Best for this stage:", TimerManager.best_times[stage_name])

func _on_backto_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
