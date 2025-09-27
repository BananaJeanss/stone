extends Button

@export var action_name: String = "right"
var waiting_for_key: bool = false

func _ready() -> void:
	# Show the first keyboard key assigned to the action (if any)
	if InputMap.has_action(action_name):
		var events: Array = InputMap.action_get_events(action_name)
		for ev in events:
			if ev is InputEventKey:
				text = _key_event_to_string(ev)
				return
	# no key found
	text = "Unassigned"

func _input(event: InputEvent) -> void:
	if not waiting_for_key:
		return

	# Only accept real key presses (ignore echoes / repeats)
	if event is InputEventKey and event.pressed and not event.echo:
		# Remove existing events for the action
		var old_events: Array = InputMap.action_get_events(action_name)
		for e in old_events:
			InputMap.action_erase_event(action_name, e)

		# Add the new key (duplicate to avoid mutating the original event)
		InputMap.action_add_event(action_name, event.duplicate())

		# Update label and stop listening
		text = _key_event_to_string(event)
		waiting_for_key = false

func _on_pressed() -> void:
	text = "Press a key..."
	waiting_for_key = true

# --- helper to convert InputEventKey -> readable string ---------------------
func _key_event_to_string(ev: InputEventKey) -> String:
	# 1) Prefer logical keycode if present (most reliable for localized key names)
	if ev.keycode != 0:
		var s := OS.get_keycode_string(ev.keycode)
		if s != "":
			return s

	# 2) Fallback to physical_keycode (non-zero when action was stored as a physical key)
	if ev.physical_keycode != 0:
		# Convert physical -> logical for the current layout, then get the label
		var logical := DisplayServer.keyboard_get_keycode_from_physical(ev.physical_keycode)
		var s2 := OS.get_keycode_string(logical)
		if s2 != "":
			return s2
		return "Key(%d)" % ev.physical_keycode

	# 3) Fallback to unicode (useful for printable keys)
	if ev.unicode != 0:
		return char(ev.unicode)

	return "Unknown"
