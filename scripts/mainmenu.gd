extends Button

var settings_page
var main_menu

func _ready() -> void:
	settings_page = get_node("/root/Menu/SettingsPage")
	main_menu = get_node("/root/Menu/MainMenu")

func _on_pressed() -> void:
	settings_page.visible = false
	main_menu.visible = true
