extends SafeMarginContainer

@export var main: PackedScene

func _ready():
	super()
	var f = FileAccess.open("user://api.dat", FileAccess.READ)
	if f:
		$VBoxContainer/TextEdit.text = f.get_as_text()

func _on_go_pressed():
	var f = FileAccess.open("user://api.dat", FileAccess.WRITE)
	f.store_string($VBoxContainer/TextEdit.text)
	get_tree().change_scene_to_packed(main)

func _on_button_pressed():
	get_tree().change_scene_to_packed(main)
