extends SafeMarginContainer

var apiKey
@export var system: Node
@export var user: Node
@export var asistant: Node
@export var input: Node
@export var setting_button: Node

func _ready():
	super()
	input.grab_focus()
	var f = FileAccess.open("user://api.dat", FileAccess.READ)
	if not f: f.store_string("")
	apiKey = f.get_as_text()

func _on_settings_pressed():
	var s = $View/Header/SettingButton/FontAwesome
	var t = create_tween()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_ELASTIC)
	t.tween_property(s, "rotation", PI*2, 0.5)
	t.tween_callback(func():
						s.rotation = 0
						get_tree().change_scene_to_file('res://assets/scenes/setting.tscn')
						)

func gpt():
	var messages = [ {
		'role': 'system',
		'content': system.text
		},
		{
		'role': 'user',
		'content': user.text
		},
	]
	var apiUrl = 'https://api.openai.com/v1/chat/completions'
	var headers = [
		'Content-type: application/json',
		'Authorization: Bearer ' + apiKey,
		'X-Slack-No-Retry: 1'
	]
	var options = {
		'model': 'gpt-3.5-turbo',
		'max_tokens' : 1024,
		'temperature' : 0.9,
		'messages': messages
	}
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._on_http_request_request_completed)
	
	var o = JSON.stringify(options)
	var _error = http_request.request(apiUrl, headers, HTTPClient.METHOD_POST, o)

func _on_http_request_request_completed(_result:int, _response_code:int, _headers:PackedStringArray, body:PackedByteArray):
	var json = JSON.parse_string(body.get_string_from_utf8())
	var message = json.choices[0].message.content
	asistant.text = message
	print(json)

func _on_user_text_submitted(_new_text:String):
	user.text = input.text
	input.text = ''
	gpt()
