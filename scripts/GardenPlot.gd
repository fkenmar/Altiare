extends "res://scripts/Interactable.gd"

## The garden plot — the overnight snowball. Plant a seed, sleep a couple of nights,
## harvest for gold: the reason to want tomorrow. Its colour reflects the growth stage,
## refreshed whenever GameState changes (e.g. after sleeping).

@onready var _visual: Polygon2D = $Visual

const STAGE_COLORS := [
	Color(0.40, 0.30, 0.20),  # 0 empty dirt
	Color(0.45, 0.38, 0.22),  # 1 seeded
	Color(0.30, 0.55, 0.25),  # 2 growing
	Color(0.85, 0.75, 0.25),  # 3 ripe
]

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
	_visual.color = STAGE_COLORS[clampi(GameState.crop_stage, 0, 3)]
