extends Control

const uuid = preload('res://assets/scripts/uuid.gd')

var apiKey
@export var view_body: Node
@export var system: Node
var _user_baloon = preload("res://assets/scenes/user_baloon.tscn")
var _assistant_baloon = preload("res://assets/scenes/assistant_baloon.tscn")
var _system_baloon = preload("res://assets/scenes/system_baloon.tscn")
var user_baloon: Node
var assistant_baloon: Node
var system_baloon: Node
@export var user: TextEdit
@export var setting_button: Node
@export var scroll: ScrollContainer
@export var vkmock1: Control
@export var vkmock2: Control
var vk_height = 0
var touch_time = 0
var touch_pos = 0
var messages = []
var temperature = 0.9
var before_rows
var user_focus = false
var title
var first_touch = true
var chat_id: String
var from
@onready var swipe_point = $Control

enum vkAnim { UP, DOWN }


func _ready():
	
	# get_node("SafeMarginContainer/Header").modulate.a = 0.1
	scroll.follow_focus = true
	var f = FileAccess.open("user://api.dat", FileAccess.READ)
	if not f: f.store_string("")
	apiKey = f.get_as_text()
	
	#grab_focus()がScrollContainerのfollow_focusに作用しない
	#回避策としてcall_defereed("grab_focus")を使用
	user.call_deferred("grab_focus")

func gpt(role: Node):
	spinner(true)
	messages.append({ 'role': role.name.to_lower(), 'content': role.text})
	role.text = ''

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
	# print("options:"); print(options); print()
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._on_http_request_request_completed)
	
	var o = JSON.stringify(options)
	var _error = http_request.request(apiUrl, headers, HTTPClient.METHOD_POST, o)

func _on_http_request_request_completed(_result:int, _response_code:int, _headers:PackedStringArray, body:PackedByteArray):
	spinner(false)
	var json = JSON.parse_string(body.get_string_from_utf8())
	messages.append(json.choices[0].message)
	print(messages); print('\n')

	add_baloon("assistant", json.choices[0].message.content)
	save()

func _on_input_submitted(_new_text:String, role: Node):
	role.text = role.text.strip_edges()
	if role.text == '':
		return

	#広がった入力欄を戻す
	if role.name.to_lower() == 'user':
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		var before_y = role.get_custom_minimum_size().y
		tween.tween_method(role.set_custom_minimum_size, Vector2(0, before_y), Vector2(0, 64), 0.2)

	create_title(role.text)
	add_baloon(role.name.to_lower(), role.text)
	save()
	gpt(role)

func _on_user_input_focus_entered():
	await get_tree().process_frame
	user_focus = true
	_on_user_input_text_changed()
	vkAnimation(vkAnim.UP)

func _on_user_input_focus_exited():
	user_focus = false
	before_rows = 0
	#広がった入力欄を戻す
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	var before_y = user.get_custom_minimum_size().y
	tween.tween_method(user.set_custom_minimum_size, Vector2(0, before_y), Vector2(0, 64), 0.2)
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
			# vk_height = 600 #TEST

	match mode:
		vkAnim.UP:
			var vk_height_before_y = vkmock1.get_custom_minimum_size().y
			var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			## t.tween_property(icon, "rotation", -PI*2, 0.5)
			## vkmock1.set_custom_minimum_size(Vector2(0, vk_height))
			tween.tween_method(vkmock1.set_custom_minimum_size, Vector2(0, vk_height_before_y), Vector2(0, vk_height), 0.425)
			tween.parallel().tween_method(vkmock2.set_custom_minimum_size, Vector2(0, vk_height_before_y), Vector2(0, vk_height), 0.425)
			## await get_tree().create_timer(0.5).timeout
			## await get_tree().process_frame
			# if first_touch:
			# 	first_touch = false
			# else:
			# 	var scrollbar = scroll.get_v_scroll_bar()
			# 	tween.parallel().tween_property(scroll, "scroll_vertical", scrollbar.max_value, 0.425)
		vkAnim.DOWN:
			# vkmock1.set_custom_minimum_size(Vector2(0, 0))
			var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tween.tween_method(vkmock1.set_custom_minimum_size, Vector2(0, vk_height), Vector2(0, 0), 0.425)
			tween.parallel().tween_method(vkmock2.set_custom_minimum_size, Vector2(0, vk_height), Vector2(0, 0), 0.425)
			# var scrollbar = scroll.get_v_scroll_bar()
			# tween.parallel().tween_property(scroll, "scroll_vertical", scrollbar.max_value, 0.425)


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
			user.release_focus()


func _on_send_button_pressed():
	_on_input_submitted("", user)

func add_baloon(role: String, text):
	var baloon
	var threshold = 16
	match role:
		"user":
			user_baloon = _user_baloon.instantiate()
			baloon = user_baloon
		"assistant":
			assistant_baloon = _assistant_baloon.instantiate()
			baloon = assistant_baloon.get_node("Assistant_baloon")
		"system":
			system_baloon = _system_baloon.instantiate()
			baloon = system_baloon
			text = '[center]%s[/center]' % text
			threshold = 32

	baloon.text = text

	#クリップボード追加による対応
	#HBOXが追加されたため
	match role:
		"assistant":
			view_body.add_child(assistant_baloon)
			view_body.move_child(assistant_baloon, view_body.get_children().size() - 3)
		_:
			view_body.add_child(baloon)
			view_body.move_child(baloon, view_body.get_children().size() - 3)

	#fit_contet = true の縦幅を記録
	baloon.fit_content = true
	var s = baloon.size
	baloon.fit_content = false

	#横スクロールアニメーション
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(baloon.set_custom_minimum_size, Vector2(0, s.y), Vector2(600, s.y), 0.4)

	#文字が徐々に出るアニメーション
	baloon.visible_ratio = 0.1
	if text.length() > threshold:
		var tween2 = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_LINEAR)
		tween2.tween_property(baloon, "visible_ratio", 1, 0.5)
	else:
		baloon.visible_ratio = 1

	#下にスクロール
	var scrollbar = scroll.get_v_scroll_bar()
	tween.parallel().tween_property(scroll, "scroll_vertical", scrollbar.max_value - 160, 1)

func _on_user_input_text_changed():
	var before_y = user.get_custom_minimum_size().y
	var rows = user.get_line_count()
	for i in range(0, user.get_line_count() - 1):
		rows += user.get_line_wrap_count(i)

	if rows != before_rows:
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_method(user.set_custom_minimum_size, Vector2(0, before_y), Vector2(0, rows*64), 0.2)
			
	before_rows = rows

func _on_user_input_gui_input(event):
	match OS.get_name():
		"iOS", "Android":
			pass
		_:
			if(event is InputEventKey) and event.shift_pressed and event.keycode == KEY_ENTER:
				_on_input_submitted("", user)
				get_viewport().set_input_as_handled()
			if(event is InputEventKey) and event.ctrl_pressed and event.keycode == KEY_ENTER:
				_on_input_submitted("", user)
				get_viewport().set_input_as_handled()
			if(event is InputEventKey) and event.meta_pressed and event.keycode == KEY_ENTER:
				_on_input_submitted("", user)
				get_viewport().set_input_as_handled()
			if(event is InputEventKey) and event.pressed and event.keycode == KEY_TAB:
				# await get_tree().process_frame
				# user.backspace()
				# get_node("SafeMarginContainer/Footer/VBoxContainer/HBoxContainer/SendButton").grab_focus()
				get_viewport().set_input_as_handled()
			if(event is InputEventMouse) and !user_focus:
				get_viewport().set_input_as_handled()

				##sendkey. TextEditはunicodeでないと反応しない
				# print("%x" % event.unicode)
				# var e = InputEventKey.new()
				## e.keycode = KEY_Y
				# e.unicode = 0x78
				# e.pressed = true
				# Input.parse_input_event(e)


func _on_system_input_submitted(_new_text):
	title = system.text
	save()
	system.release_focus()
	# _on_input_submitted("", system)
	
func create_title(text):
	if title == null:
		title = text
		system.text = title

func save():
	var data = { 'title': title, 'messages': messages }

	DirAccess.make_dir_absolute("user://chats/")
	var f = FileAccess.open("user://chats/%s" % chat_id, FileAccess.WRITE)
	f.store_line(JSON.stringify(data, "\t"))
	
func _on_back_button_pressed():
	# get_tree().change_scene_to_file('res://assets/scenes/chat_index.tscn')
	exit()

func load_chats():
	for message in messages:
		add_baloon(message["role"], message["content"])
	system.text = title

func load_chat(filename) -> Dictionary:
	var f = FileAccess.open("user://chats/%s" % filename, FileAccess.READ)
	if !f:
		return {}
	var contents = f.get_as_text()
	var dict = JSON.parse_string((contents))
	return dict

func _on_system_focus_exited():
	_on_system_input_submitted('')

# func _input(event):
	# print(event)

var twe
func spinner(show_spinner=true):
	var _spinner = get_node("SafeMarginContainer/Header/Control/Spinner")
	if show_spinner:
		var spinner_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR).set_loops()
		twe = spinner_tween
		_spinner.show()
		spinner_tween.parallel().tween_property(_spinner, "rotation", TAU, 2).as_relative()
	else:
		twe.kill()
		_spinner.hide()
		# var spinner_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
		# spinner_tween.tween_property(_spinner, "modulate", Color(55,55,55,0), 1)
		# spinner_tween.parallel().tween_property(_spinner, "rotation", TAU, 1)

func enter(scene, id: String):
	scene.add_child(self)
	if id == "":
		chat_id = uuid.v4()
	else:
		chat_id = id
		var saved_data = load_chat(chat_id)
		messages = saved_data["messages"]
		title = saved_data["title"]
		load_chats()
	
func exit():
	queue_free()

var swipe_initial_pos
func _on_control_gui_input(event):
	if (event is InputEventMouseButton) and event.is_pressed():
		swipe_initial_pos = event.position
		print(self.size.x / 2)
	if (event is InputEventScreenDrag):
		var pos = swipe_initial_pos - event.position
		var deadpoint = self.size.x / 2
		self.position.x = -pos.x
		if self.position.x > deadpoint:
			var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
			tween.tween_property(self, "position:x", self.size.x, 0.5)
			tween.tween_callback(exit)
	if (event is InputEventMouseButton) and !event.is_pressed():
		self.position.x = 0

