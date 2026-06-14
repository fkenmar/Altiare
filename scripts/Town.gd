extends Node2D

## The town level root (y-sorted, so the player passes behind taller things). Builds
## its grassy floor via TileFloorBuilder and scatters non-colliding decoration to make
## the place feel lived-in. Walls, buildings, the bed, dungeon door, NPC, board, garden,
## and the player live in Town.tscn. Collision is on the StaticBody2D wall border.

const TileFloorBuilder = preload("res://scripts/TileFloorBuilder.gd")
const PixelArt = preload("res://scripts/PixelArt.gd")

const TILE_SIZE: int = 32
const WIDTH: int = 20   # tiles wide
const HEIGHT: int = 15  # tiles tall

# Decoration placed clear of the interactables / player spawn: [kind, x, y].
const DECOR := [
	["tree", 72, 84], ["tree", 576, 96], ["tree", 88, 432], ["tree", 560, 430], ["tree", 520, 78],
	["bush", 120, 180], ["bush", 484, 140], ["bush", 300, 404], ["bush", 150, 300],
	["rock", 392, 172], ["rock", 130, 384], ["rock", 500, 286],
]

@onready var _ground: TileMapLayer = $Ground

func _ready() -> void:
	TileFloorBuilder.build(_ground, WIDTH, HEIGHT, TILE_SIZE, "town")
	_scatter_decor()

func _scatter_decor() -> void:
	for item in DECOR:
		var s := Sprite2D.new()
		match item[0]:
			"tree":
				s.texture = PixelArt.tree()
			"bush":
				s.texture = PixelArt.bush()
			"rock":
				s.texture = PixelArt.rock()
		s.position = Vector2(item[1], item[2])
		add_child(s)  # direct child of the y-sorted Town, so it sorts against the player
