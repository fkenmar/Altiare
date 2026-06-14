extends "res://scripts/Interactable.gd"

## The garden plot — the overnight snowball. Plant a seed, sleep a couple of nights,
## harvest for gold. Its sprite reflects the growth stage (tilled soil -> sprout ->
## plant -> ripe), regenerated only when the stage actually changes (stats_changed
## fires often, so we guard against rebuilding the texture every emit).

const PixelArt = preload("res://scripts/PixelArt.gd")

@onready var _visual: Sprite2D = $Visual

var _last_stage: int = -1

func _on_ready() -> void:
	GameState.stats_changed.connect(_update_visual)
	_update_visual()

func get_prompt() -> String:
	match GameState.crop_stage:
		0: return "plant a seed"
		3: return "harvest the crop"
		_: return "let the crop grow"

func _interact() -> void:
	GameState.message_shown.emit(GameState.plant_crop())

func _update_visual() -> void:
	var s := clampi(GameState.crop_stage, 0, 3)
	if s == _last_stage:
		return
	_last_stage = s
	_visual.texture = PixelArt.tilled(s)
