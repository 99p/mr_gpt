extends Control

var apiKey
@export var view_body: Node
@export var system: Node
var user_baloon = preload("res://assets/scenes/user_baloon.tscn")
var assistant_baloon = preload("res://assets/scenes/assistant_baloon.tscn")
var user: Node
var assistant: Node
@export var input: Node
@export var setting_button: Node
@export var scroll: ScrollContainer
@export var vkmock1: Control
@export var vkmock2: Control
var vk_height = 0
var touch_time = 0
var touch_pos = 0
var messages = []
var temperature = 0.9

enum vkAnim { UP, DOWN }

func _ready():
	scroll.follow_focus = true
	var f = FileAccess.open("user://api.dat", FileAccess.READ)
	if not f: f.store_string("")
	apiKey = f.get_as_text()
	
	#grab_focus()がScrollContainerのfollow_focusに作用しない
	#回避策としてcall_defereed("grab_focus")を使用
	input.call_deferred("grab_focus")

func _on_settings_pressed():
	var icon = setting_button.get_node("FontAwesome")
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(icon, "rotation", PI*2, 0.5)
	tween.tween_callback(func():
						icon.rotation = 0
						get_tree().change_scene_to_file('res://assets/scenes/setting.tscn')
						)

func gpt():
	# var messages = [ {
	# 	'role': 'system',
	# 	'content': system.text
	# 	},
	# 	{
	# 	'role': 'user',
	# 	'content': user.text
	# 	},
	# ]
	messages.append({ 'role': 'user', 'content': user.text})

	var apiUrl = 'https://api.openai.com/v1/chat/completions'
	var headers = [
		'Content-type: application/json',
		'Authorization: Bearer ' + apiKey,
		'X-Slack-No-Retry: 1'
	]
	var options = {
		'model': 'gpt-3.5-turbo',
		'max_tokens' : 1024,
		'temperature' : temperature,
		'messages': messages
	}
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._on_http_request_request_completed)
	
	var o = JSON.stringify(options)
	var _error = http_request.request(apiUrl, headers, HTTPClient.METHOD_POST, o)

func _on_http_request_request_completed(_result:int, _response_code:int, _headers:PackedStringArray, body:PackedByteArray):
	var json = JSON.parse_string(body.get_string_from_utf8())
	messages.append(json.choices[0].message)
	print(json)

	assistant = assistant_baloon.instantiate()
	assistant.name = "Assistant"
	view_body.add_child(assistant)
	view_body.move_child(assistant, view_body.get_children().size() - 3)
	assistant.text = json.choices[0].message.content

	var scrollbar = scroll.get_v_scroll_bar()
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(scroll, "scroll_vertical", scrollbar.max_value, 1)

func _on_user_text_submitted(_new_text:String):
	user = user_baloon.instantiate()
	user.name = "User"
	view_body.add_child(user)
	view_body.move_child(user, view_body.get_children().size() - 3)
	user.text = input.text
	input.text = ''
	input.release_focus()
	gpt()

func _on_input_focus_entered():
	vkAnimation(vkAnim.UP)

func _on_input_focus_exited():
	vkAnimation(vkAnim.DOWN)

func vkAnimation(mode):
	match OS.get_name():
		"iOS", "Android":
			# iPhone mini 12 実機では1008
			# 時間差がある
			# vk_height = DisplayServer.vkmock1_get_vk_height()
			vk_height = 580
		_:
			vk_height = 0
			# vk_height = 600

	match mode:
		vkAnim.UP:
			var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			# t.tween_property(icon, "rotation", -PI*2, 0.5)
			# vkmock1.set_custom_minimum_size(Vector2(0, vk_height))
			tween.tween_method(vkmock1.set_custom_minimum_size, Vector2(0, 0), Vector2(0, vk_height), 0.425)
			tween.parallel().tween_method(vkmock2.set_custom_minimum_size, Vector2(0, 0), Vector2(0, vk_height), 0.425)
			# await get_tree().create_timer(0.5).timeout
			# await get_tree().process_frame
			var scrollbar = scroll.get_v_scroll_bar()
			# scroll.scroll_vertical = scrollbar.max_value
			tween.parallel().tween_property(scroll, "scroll_vertical", scrollbar.max_value, 0.425)
		vkAnim.DOWN:
			# vkmock1.set_custom_minimum_size(Vector2(0, 0))
			var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tween.tween_method(vkmock1.set_custom_minimum_size, Vector2(0, vk_height), Vector2(0, 0), 0.425)
			tween.parallel().tween_method(vkmock2.set_custom_minimum_size, Vector2(0, vk_height), Vector2(0, 0), 0.425)
			var scrollbar = scroll.get_v_scroll_bar()
			tween.parallel().tween_property(scroll, "scroll_vertical", scrollbar.max_value, 0.425)


func _on_view_gui_input(event:InputEvent):
	if (event is InputEventMouseButton) and event.pressed:
		touch_time = Time.get_unix_time_from_system()
		touch_pos = event.position
	if (event is InputEventMouseButton) and !event.pressed:
		var timeDelta = Time.get_unix_time_from_system() - touch_time
		var posDelta = abs(event.position.length() - touch_pos.length())
		if 0.1 > timeDelta and 10 > posDelta:
			system.release_focus()
			input.release_focus()

