extends Node2D

## The town level root. Builds its floor via the shared TileFloorBuilder; the walls,
## building entrance, bed, and dungeon door are placed in Town.tscn. Collision lives
## on the StaticBody2D wall border, not the tiles (simplest "bump the walls").

const TileFloorBuilder = preload("res://scripts/TileFloorBuilder.gd")

const TILE_SIZE: int = 32
const WIDTH: int = 20   # tiles wide
const HEIGHT: int = 15  # tiles tall

const FLOOR_COLOR := Color(0.25, 0.5, 0.28)  # grass green
const WALL_COLOR := Color(0.36, 0.27, 0.18)  # earthy brown

@onready var _ground: TileMapLayer = $Ground

func _ready() -> void:
	TileFloorBuilder.build(_ground, WIDTH, HEIGHT, TILE_SIZE, FLOOR_COLOR, WALL_COLOR)
