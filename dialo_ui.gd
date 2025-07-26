# ChatUI.gd
extends Control

@onready var chat_display: Label = $VBoxContainer/ScrollContainer/ChatLabel
@onready var input_field: LineEdit = $VBoxContainer/HBoxContainer/LineEdit
@onready var send_button: Button = $VBoxContainer/HBoxContainer/SendButton
@onready var clear_button: Button = $VBoxContainer/HBoxContainer/ClearButton

func _ready():
	# 初始化历史记录
	AiManager.load_history()
	for msg in AiManager.messages:
		chat_display.text += "[%s] %s\n" % [msg["sender"], msg["text"]]
	
	input_field.grab_focus()
	input_field.text_submitted.connect(_on_text_submitted)
	send_button.pressed.connect(_on_send_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	
	# 连接AI响应信号（简化版）
	AiManager.ai_response_received.connect(_on_ai_response)
	self.process_mode = Node.PROCESS_MODE_ALWAYS


func _on_text_submitted(text: String):
	await _process_message(text)

func _on_send_pressed():
	await _process_message(input_field.text)

func _process_message(text: String) -> void:
	var clean_text = text.strip_edges() 
	if clean_text.is_empty(): return
	
	add_message("你", clean_text)
	input_field.clear()
	AiManager.send_message(clean_text)

func add_message(sender: String, text: String):
	chat_display.text += "[%s] %s\n" % [sender, text]
	scroll_to_bottom()

func _on_clear_pressed():
	AiManager.clear_history()
	chat_display.text = ""

func _on_ai_response(text: String):
	# 直接显示完整消息（如需打字机效果应在AIManager实现）
	add_message("AI", text)

func scroll_to_bottom():
	await get_tree().process_frame
	$VBoxContainer/ScrollContainer.scroll_vertical = int(1e8)
