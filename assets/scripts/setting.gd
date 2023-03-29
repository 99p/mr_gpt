extends Control
# signal sample_pressed

@export var main: PackedScene

func _ready():
	var f = FileAccess.open("user://api.dat", FileAccess.READ)
	if f:
		$SafeMarginContainer/VBoxContainer/TextEdit.text = f.get_as_text()
	f.close()

func _on_go_pressed():
	var f = FileAccess.open("user://api.dat", FileAccess.WRITE)
	f.store_string($SafeMarginContainer/VBoxContainer/TextEdit.text)
	f.close()
	# $SafeMarginContainer/VBoxContainer/TextEdit.text = f.get_as_text()
	# get_tree().change_scene_to_packed(main)

func _on_button_pressed():
	# get_tree().change_scene_to_packed(main)
	queue_free()

func _on_go_to_sample_scene_pressed():
	# get_tree().change_scene_to_file("res://assets/scenes/sample.tscn")
	preload("res://assets/scenes/sample.tscn").instantiate().enter(self)
	# queue_free()

func enter(from):
	from.add_child(self)

