extends Control

@export var view_body: Node
var _chat_baloon = preload("res://assets/scenes/chat_baloon.tscn")

func _ready():
	var ids = load_chats()
	if ids:
		add_baloons(ids)
	# print(ids)

func load_chats():
	var dir = DirAccess.open("user://chats/")
	var files = []
	if dir:
		dir.list_dir_begin()
		var filename = dir.get_next()
		while filename != "":
			files.push_back(load_chat(filename))
			filename = dir.get_next()
		return files
	
func load_chat(filename) -> Dictionary:
	var f = FileAccess.open("user://chats/%s" % filename, FileAccess.READ)
	var contents = f.get_as_text()
	var dict = JSON.parse_string((contents))
	return {"id": filename, "title": dict['title']}

func add_baloons(chats:Array):
	print(chats)
	for chat in chats:
		var chat_baloon = _chat_baloon.instantiate()
		chat_baloon.text = chat["title"]
		chat_baloon.pressed.connect(_on_chat_baloon_pressed.bind(chat["id"]))
		view_body.add_child(chat_baloon)
		view_body.move_child(chat_baloon, view_body.get_children().size() - 3)

func _on_chat_baloon_pressed(id):
	Global.chat_id = id
	get_tree().change_scene_to_file('res://assets/scenes/chat.tscn')

func _on_settings_pressed():
	var icon = get_node("SafeMarginContainer/Header/HBoxContainer/System/SettingButton/FontAwesome")
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(icon, "rotation", PI*2, 0.5)
	tween.tween_callback(func():
						icon.rotation = 0
						get_tree().change_scene_to_file('res://assets/scenes/setting.tscn')
						)
