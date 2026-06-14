extends "res://scripts/Interactable.gd"

## The tavern bounty board. Claim a monster-slaying bounty for gold; each completion
## raises the next one — a non-combat reason to keep coming back to town.

const PixelArt = preload("res://scripts/PixelArt.gd")

@onready var _visual: Sprite2D = $Visual

func _on_ready() -> void:
	prompt = "check the bounty board"
	_visual.texture = PixelArt.sign()

func _interact() -> void:
	GameState.message_shown.emit(GameState.claim_bounty())
