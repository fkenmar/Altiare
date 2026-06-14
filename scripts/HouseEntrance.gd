extends Area2D

## The building entrance — a little cottage. For now it just announces entry on
## body_entered (later it could swap to an interior). collision_mask is the player layer.

const PixelArt = preload("res://scripts/PixelArt.gd")

@onready var _visual: Sprite2D = $Visual

func _ready() -> void:
	_visual.texture = PixelArt.house()
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("entered house")
