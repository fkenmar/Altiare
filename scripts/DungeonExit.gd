extends Area2D

## Dungeon → town transition (the stairs back up).

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Climbing back to town...")
		get_tree().change_scene_to_file("res://scenes/World.tscn")
