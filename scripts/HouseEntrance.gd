extends Area2D

## Building entrance trigger. For M1 it just announces entry (later it'll swap to an
## interior scene). Connects its own body_entered signal (prefer signals — see
## CLAUDE.md); its collision_mask is the player layer, so only the player trips it.

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("entered house")
