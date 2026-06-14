extends "res://scripts/Interactable.gd"

## A villager you can talk to. Cycles through its dialogue lines on each interact —
## the cheap way to make the town feel inhabited.

@export var npc_name: String = "Villager"
@export var lines: PackedStringArray = PackedStringArray([
	"Welcome, summoned one. I'm Mira. Don't worry - the dizziness fades.",
	"That cave to the north is the dungeon. Walk into a monster to fight; every swing spends energy.",
	"Press [C] for your Status Window - inspect foes with [F], and pour level-up points into Strength or Vitality.",
	"When energy runs low, come home and sleep. A new day restores you... and ripens whatever you've planted.",
	"Tend the garden, claim bounties at the board. Build the life you want here. We're glad you came.",
])

var _line: int = 0

func _on_ready() -> void:
	prompt = "talk to %s" % npc_name

func _interact() -> void:
	if lines.is_empty():
		return
	GameState.message_shown.emit("%s: %s" % [npc_name, lines[_line]])
	_line = (_line + 1) % lines.size()
