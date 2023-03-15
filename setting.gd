extends Control

func _ready():
	var f = FileAccess.open("user://api.dat", FileAccess.READ)
	if f:
		$TextEdit.text = f.get_as_text()

func _on_go_pressed():
	var f = FileAccess.open("user://api.dat", FileAccess.WRITE)
	f.store_string($TextEdit.text)
	get_tree().change_scene_to_file("res://main.tscn")

