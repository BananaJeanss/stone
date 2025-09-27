extends Control

var settings_page
var main_menu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	settings_page = get_node("/root/Menu/SettingsPage")
	main_menu = get_node("/root/Menu/MainMenu")

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/World.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed() -> void:
	settings_page.visible = true
	main_menu.visible = false
