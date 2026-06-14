extends Area2D

## The bed. While the player stands on it, pressing the interact key (ui_accept =
## Space/Enter) advances the day via GameState and refills energy. Overlap is tracked
## through its own signals (prefer signals — see CLAUDE.md); collision_mask is the
## player layer so only the player counts.

var _player_on_bed: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_on_bed = true
		print("On the bed — press Space/Enter to sleep.")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_on_bed = false

func _unhandled_input(event: InputEvent) -> void:
	if _player_on_bed and event.is_action_pressed("ui_accept"):
		GameState.sleep()
		print("Day %d — energy refilled to %d." % [GameState.day, GameState.energy])
