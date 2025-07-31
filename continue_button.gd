extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	self.pressed.connect(_continue_scene)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _continue_scene() -> void:
	get_tree().paused = false
