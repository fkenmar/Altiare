extends Node

## Global game state singleton (autoload). Holds the day/energy the whole game
## hangs off of — every other system reads and writes through here (see CLAUDE.md).

# Tuning lives at the top as constants, per project conventions.
const STARTING_DAY: int = 1
const MAX_ENERGY: int = 100

var day: int = STARTING_DAY
var energy: int = MAX_ENERGY

## Advance the world by one day and refill energy. Called when the player sleeps.
func sleep() -> void:
	day += 1
	energy = MAX_ENERGY
