extends Node2D

## The dungeon floor. Builds its (darker) tile floor via the shared TileFloorBuilder;
## walls, the exit stairs, the player spawn, and monsters are placed in Dungeon.tscn.
## Listens for GameState.player_fainted to drag the player back to town.

const TileFloorBuilder = preload("res://scripts/TileFloorBuilder.gd")

const TILE_SIZE: int = 32
const WIDTH: int = 16
const HEIGHT: int = 12

const FLOOR_COLOR := Color(0.16, 0.16, 0.2)  # cold stone
const WALL_COLOR := Color(0.08, 0.08, 0.1)   # near-black

var _returning: bool = false

@onready var _ground: TileMapLayer = $Ground

func _ready() -> void:
	TileFloorBuilder.build(_ground, WIDTH, HEIGHT, TILE_SIZE, FLOOR_COLOR, WALL_COLOR)
	GameState.player_fainted.connect(_on_player_fainted)

func _on_player_fainted() -> void:
	if _returning:
		return  # one faint, one trip home (multiple monsters can zero us in a frame)
	_returning = true
	GameState.hp = 1  # dragged home barely conscious; sleep to recover
	print("You fainted! Dragged back to town.")
	get_tree().change_scene_to_file("res://scenes/World.tscn")
