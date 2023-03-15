extends Control

var apiKey

func _ready():
	var f = FileAccess.open("user://api.dat", FileAccess.READ)
	if not f: f.store_string("")
	apiKey = f.get_as_text()

func _on_button_pressed():
	# get_node("HTTPRequest").request("http://www.mocky.io/v2/5185415ba171ea3a00704eed")
	gpt()

func _on_http_request_request_completed(result:int, response_code:int, headers:PackedStringArray, body:PackedByteArray):
	var json = JSON.parse_string(body.get_string_from_utf8())
	var message = json.choices[0].message.content
	$GPT/Asistant.text = message

func _on_settings_pressed():
	var s = get_node("Settings")
	var t = create_tween()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_ELASTIC)
	t.tween_property(s, "rotation", PI*2, 1)
	t.tween_callback(func():
						s.rotation = 0
						get_tree().change_scene_to_file('res://setting.tscn')
						)

func gpt():
	var messages = [ {
		'role': 'system',
		'content': $GPT/System.text
		},
		{
		'role': 'user',
		'content': $GPT/User.text
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
