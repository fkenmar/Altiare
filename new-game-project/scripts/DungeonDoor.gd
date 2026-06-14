extends Area2D

## Town -> dungeon transition, drawn as a cave mouth. Stepping on it descends; the
## GameState autoload carries stats across the scene change.

const PixelArt = preload("res://scripts/PixelArt.gd")

@onready var _visual: Sprite2D = $Visual

func _ready() -> void:
	_visual.texture = PixelArt.cave()
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Descending into the dungeon...")
		get_tree().change_scene_to_file("res://scenes/Dungeon.tscn")
