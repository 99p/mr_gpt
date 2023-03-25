extends Control

var apiKey
@export var view_body: Node
@export var system: Node
var user_baloon = preload("res://assets/scenes/user_baloon.tscn")
var assistant_baloon = preload("res://assets/scenes/assistant_baloon.tscn")
var user: Node
var assistant: Node
@export var input: TextEdit
@export var setting_button: Node
@export var scroll: ScrollContainer
@export var vkmock1: Control
@export var vkmock2: Control
var vk_height = 0
var touch_time = 0
var touch_pos = 0
var messages = []
var temperature = 0.9
var before_input_count

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
	# print(json)

	add_baloon("assistant", json.choices[0].message.content)

func _on_user_text_submitted(_new_text:String):
	if input.text == '':
		return
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	var before_y = input.get_custom_minimum_size().y
	tween.tween_method(input.set_custom_minimum_size, Vector2(0, before_y), Vector2(0, 64), 0.2)

	add_baloon("user", input.text)
	input.text = ''
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


# input外タップでアンフォーカス
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


func _on_send_button_pressed():
	_on_user_text_submitted("")

func add_baloon(role, text):
	var baloon
	match role:
		"user":
			user = user_baloon.instantiate()
			baloon = user
		"assistant":
			assistant = assistant_baloon.instantiate()
			baloon = assistant
	baloon.text = text
	view_body.add_child(baloon)
	var s = baloon.size
	baloon.fit_content = false
	baloon.visible_ratio = 0.1
	view_body.move_child(baloon, view_body.get_children().size() - 3)
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(baloon.set_custom_minimum_size, Vector2(0, s.y), Vector2(600, s.y), 0.4)
	if text.length() > 16:
		var tween2 = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_LINEAR)
		tween2.tween_property(baloon, "visible_ratio", 1, 0.5)
	else:
		baloon.visible_ratio = 1
	var scrollbar = scroll.get_v_scroll_bar()
	tween.parallel().tween_property(scroll, "scroll_vertical", scrollbar.max_value, 1)

func _on_input_text_changed():
	var before_y = input.get_custom_minimum_size().y
	var input_count = input.get_line_count()
	for i in range(0, input.get_line_count() - 1):
		input_count += input.get_line_wrap_count(i)

	if input_count != before_input_count:
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_method(input.set_custom_minimum_size, Vector2(0, before_y), Vector2(0, input_count*64), 0.2)
			
	before_input_count = input_count

func _on_input_gui_input(event):
	# var timer = input.get_node("Timer")
	# if !timer.time_left:
	if(event is InputEventKey) and event.shift_pressed and event.keycode == KEY_ENTER:
		_on_user_text_submitted("")
			# timer.start()
	if(event is InputEventKey) and event.ctrl_pressed and event.keycode == KEY_ENTER:
		_on_user_text_submitted("")
			# timer.start()
