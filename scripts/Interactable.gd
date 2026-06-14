extends Area2D

## Base for "stand on it, press the interact key (ui_accept)" objects (bed, NPCs,
## bounty board, garden). Subclasses set `prompt` (or override get_prompt) and override
## _interact(). collision_mask is the player layer, so only the player trips it; the
## contextual prompt is routed to the HUD through GameState.prompt_changed.

@export var prompt: String = "interact"

var _player_in_range: bool = false

func _ready() -> void:
	body_entered.connect(_on_entered)
	body_exited.connect(_on_exited)
	_on_ready()

func _on_ready() -> void:
	pass  # subclass setup hook

func get_prompt() -> String:
	return prompt  # subclasses may override for stateful prompts

func _on_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		GameState.prompt_changed.emit(get_prompt())

func _on_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		GameState.prompt_changed.emit("")

func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and event.is_action_pressed("ui_accept"):
		_interact()

func _interact() -> void:
	pass  # subclass overrides
