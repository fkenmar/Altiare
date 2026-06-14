extends Node2D

## The town level root. Builds its grassy floor via the shared TileFloorBuilder; the
## walls, building, bed, dungeon door, NPC, board, garden, and decoration are placed in
## Town.tscn. Collision lives on the StaticBody2D wall border, not the tiles.

const TileFloorBuilder = preload("res://scripts/TileFloorBuilder.gd")

const TILE_SIZE: int = 32
const WIDTH: int = 20   # tiles wide
const HEIGHT: int = 15  # tiles tall

@onready var _ground: TileMapLayer = $Ground

func _ready() -> void:
	TileFloorBuilder.build(_ground, WIDTH, HEIGHT, TILE_SIZE, "town")
