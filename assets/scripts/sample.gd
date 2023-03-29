extends Control

func _ready():
	print(OS.low_processor_usage_mode)

func _process(_delta):
	# print(DisplayServer.mouse_get_position())
	# print("canvasItem_global:")
	# print(get_global_mouse_position())
	# print("canvasItem_local:")
	# print(get_local_mouse_position())
	# print("viewport:")
	# print(get_viewport().gui_get_drag_data())
	
# func _input(event):
	# print(event)
	pass

func _on_button_pressed(value):
	Input.vibrate_handheld(value)
	
func enter(from)
	from.add_child(self)
