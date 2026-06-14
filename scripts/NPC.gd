extends "res://scripts/Interactable.gd"

## A villager you can talk to. Cycles through its dialogue lines on each interact —
## the cheap way to make the town feel inhabited.

@export var npc_name: String = "Villager"
@export var lines: PackedStringArray = PackedStringArray([
	"Oh! A new face. Welcome to the frontier, traveler.",
	"That cave at the edge of town? Monsters. Strong folk descend to grow stronger.",
	"Me, I just tend my garden. There's a free plot if you fancy trying.",
])

var _line: int = 0

func _on_ready() -> void:
	prompt = "talk to %s" % npc_name

func _interact() -> void:
	if lines.is_empty():
		return
	GameState.message_shown.emit("%s: %s" % [npc_name, lines[_line]])
	_line = (_line + 1) % lines.size()
