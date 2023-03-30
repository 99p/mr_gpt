extends RichTextLabel

enum role { SYSTEM, USER, ASISTANT }

var clipboard

func _ready():
	$Timer.timeout.connect(_on_timer_timeout)
	gui_input.connect(_on_gui_input)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	if get_parent().get_node_or_null("ClipboardButton"):
		clipboard = $"../ClipboardButton"
		clipboard.button_down.connect(_on_clipboard_button_down)

func _gui_input(event):
	if (event is InputEventMouse) and !event.is_pressed():
		$Timer.stop()

func _on_gui_input(event):
	if (event is InputEventMouse) and event.is_pressed():
		$Timer.start(0.5)

func _on_timer_timeout():
	if clipboard:
		clipboard.show()
	Input.vibrate_handheld(20)
	selection_enabled = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func _on_focus_entered():
	pass

func _on_focus_exited():
	if clipboard:
		# await get_tree().create_timer(0.1).timeout
		clipboard.call_deferred("hide")
	selection_enabled = false
	mouse_filter = Control.MOUSE_FILTER_PASS

func _on_clipboard_button_down():
	DisplayServer.clipboard_set(text)
	clipboard.hide()
