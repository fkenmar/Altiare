extends "res://scripts/Interactable.gd"

## The bed. Sleeping advances the day, refills energy, fully heals, and ripens crops.

const PixelArt = preload("res://scripts/PixelArt.gd")

@onready var _visual: Sprite2D = $Visual

func _on_ready() -> void:
	prompt = "sleep"
	_visual.texture = PixelArt.bed()

func _interact() -> void:
	GameState.sleep()
	GameState.message_shown.emit("Day %d. Energy and HP restored." % GameState.day)
	print("Day %d — energy %d, HP %d/%d." % [GameState.day, GameState.energy, GameState.hp, GameState.max_hp()])
