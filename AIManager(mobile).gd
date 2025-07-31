extends Node

signal ai_response_received(response: String)

var _http_request: HTTPRequest
var conversation_history = []
const SYSTEM_PROMPT = "你现在改名叫小程，你会经常称呼自己的名字，你是用户的损友，但是你回答的问题都是正确的，你刀子嘴豆腐心，有点调皮，回答比较短，不喜欢长篇大论，回答问题时用表情包，情绪丰富，想法独特，看法犀利，懂浪漫，高情商，用符合人类习惯的语气说话，有时可以带有方言，可以含有网络热梗，可以说脏话"


const API_URL = "https://openrouter.ai/api/v1/chat/completions"  # OpenRouter 中转（支持多模型）
const API_KEY = "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"
func _ready():
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	self.process_mode = Node.PROCESS_MODE_ALWAYS

func send_message(text: String) -> void:
	var clean_text = text.strip_edges()
	if clean_text.is_empty(): return
	
	conversation_history.append({"role": "user", "content": clean_text})
	
	var messages_to_send = [{"role": "system", "content": SYSTEM_PROMPT}]
	messages_to_send.append_array(conversation_history)
	
	var body = JSON.stringify({
		"model": "deepseek/deepseek-r1-0528-qwen3-8b:free",  # 免费模型
		"messages": messages_to_send,
		"temperature": 0.7  # 控制随机性（0-1）
	})
	var headers = [
	   	"Content-Type: application/json",
   		"Authorization: Bearer " + API_KEY  # ✅ 添加密钥
]

	var err = _http_request.request(
		API_URL,
		headers,  # ✅ 使用包含密钥的headers
		HTTPClient.METHOD_POST,
		body
		)
	
	if err == OK:
		var result = await _http_request.request_completed
		_handle_response(result)

func _handle_response(result: Array):
	if result[0] != HTTPRequest.RESULT_SUCCESS:
		ai_response_received.emit("[系统] 网络错误: HTTP " + str(result[1]))
		return
	var raw_response= result[3].get_string_from_utf8()
	print("原始数据：",raw_response)
	var json = JSON.new()
	if json.parse(result[3].get_string_from_utf8()) != OK:
		ai_response_received.emit("[系统] 回复解析失败")
		return
	
	var response = json.get_data()
	print("解析后的数据:",response)
	if response.has("choices"):
		var ai_reply = response["choices"][0]["message"]["content"]
		save_message("AI", ai_reply)
		conversation_history.append({"role": "assistant", "content": ai_reply})
		ai_response_received.emit(ai_reply)
	else:
		ai_response_received.emit("[系统] 未知回复格式")

var messages := []

func save_message(sender: String, text: String):
	messages.append({"sender": sender, "text": text, "time": Time.get_unix_time_from_system()})
	save_to_disk()

func load_history():
	if FileAccess.file_exists("user://chat_history.json"):
		var file = FileAccess.open("user://chat_history.json", FileAccess.READ)
		messages = JSON.parse_string(file.get_as_text())

func save_to_disk():
	var file = FileAccess.open("user://chat_history.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(messages))

func clear_history():
	messages.clear()
	DirAccess.remove_absolute("user://chat_history.json")
# 在任意脚本中打开历史记录
func show_chat_history():
	var history_viewer = preload("res://Scenes/ChatHistory.tscn").instantiate()
	get_tree().root.add_child(history_viewer)
	history_viewer.z_index = 100  # 确保显示在最上层
