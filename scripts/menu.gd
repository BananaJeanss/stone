extends Control

var settings_page
var main_menu
var stages_menu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	settings_page = get_node("/root/Menu/SettingsPage")
	main_menu = get_node("/root/Menu/MainMenu")
	stages_menu = get_node("/root/Menu/StagesMenu")

func _on_start_pressed() -> void:
	main_menu.visible = false
	stages_menu.visible = true
	# get_tree().change_scene_to_file("res://scenes/World.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed() -> void:
	settings_page.visible = true
	main_menu.visible = false


func _on_main_menu_button_pressed() -> void:
	settings_page.visible = false
	stages_menu.visible = false
	main_menu.visible = true


func _on_stage_1_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/World.tscn")


func _on_stage_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world2.tscn")


func _on_stage_3_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world3.tscn")
