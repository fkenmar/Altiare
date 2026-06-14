extends Area2D

## Town → dungeon transition. Stepping onto it descends to the dungeon floor; the
## GameState autoload carries stats across the scene change.

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Descending into the dungeon...")
		get_tree().change_scene_to_file("res://scenes/Dungeon.tscn")
