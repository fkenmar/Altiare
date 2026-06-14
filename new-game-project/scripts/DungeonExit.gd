extends Area2D

## Dungeon -> town transition, drawn as stairs back up to the light.

const PixelArt = preload("res://scripts/PixelArt.gd")

@onready var _visual: Sprite2D = $Visual

func _ready() -> void:
	_visual.texture = PixelArt.stairs()
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Climbing back to town...")
		get_tree().change_scene_to_file("res://scenes/World.tscn")
