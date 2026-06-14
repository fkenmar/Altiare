extends Node2D

## The town level root (y-sorted, so the player passes behind taller things). Builds
## its grassy floor via TileFloorBuilder, scatters non-colliding decoration to make the
## place feel lived-in, and clamps the camera to the map so no void shows at the edges.
## Walls, buildings, bed, dungeon door, NPC, board, garden, and the player live in
## Town.tscn. Collision is on the StaticBody2D wall border.

const TileFloorBuilder = preload("res://scripts/TileFloorBuilder.gd")
const PixelArt = preload("res://scripts/PixelArt.gd")

const TILE_SIZE: int = 32
const WIDTH: int = 20   # tiles wide
const HEIGHT: int = 15  # tiles tall
const PATH_TILE := Vector2i(5, 0)  # atlas index of the dirt-path tile

# Decoration placed clear of the interactables / player spawn: [kind, x, y].
const DECOR := [
	["tree", 72, 84], ["tree", 576, 96], ["tree", 88, 432], ["tree", 560, 430], ["tree", 520, 78],
	["bush", 120, 180], ["bush", 484, 140], ["bush", 300, 404], ["bush", 150, 300],
	["rock", 392, 172], ["rock", 130, 384], ["rock", 500, 286],
]

@onready var _ground: TileMapLayer = $Ground

func _ready() -> void:
	TileFloorBuilder.build(_ground, WIDTH, HEIGHT, TILE_SIZE, "town")
	_paint_paths()
	_scatter_decor()
	_clamp_camera()

func _scatter_decor() -> void:
	var cache := {}  # one texture per kind, shared across instances
	for item in DECOR:
		var kind: String = item[0]
		if not cache.has(kind):
			match kind:
				"tree":
					cache[kind] = PixelArt.tree()
				"bush":
					cache[kind] = PixelArt.bush()
				"rock":
					cache[kind] = PixelArt.rock()
		var s := Sprite2D.new()
		s.texture = cache[kind]
		s.position = Vector2(item[1], item[2])
		add_child(s)  # direct child of the y-sorted Town, so it sorts against the player

## Paint a dirt path: a central road (row 7) with spurs to the cottage, dungeon, garden,
## and bed, so the town reads as a designed village instead of props scattered on a field.
func _paint_paths() -> void:
	var cells: Array[Vector2i] = []
	for x in range(3, 17):
		cells.append(Vector2i(x, 7))
	for y in range(4, 7):
		cells.append(Vector2i(5, y))
		cells.append(Vector2i(10, y))
	for y in range(8, 11):
		cells.append(Vector2i(7, y))
		cells.append(Vector2i(14, y))
	for c in cells:
		_ground.set_cell(c, 0, PATH_TILE)

## Clamp the player's camera to the map bounds so the cozy 2x zoom never shows the void.
func _clamp_camera() -> void:
	var cam := get_node_or_null("Player/Camera2D") as Camera2D
	if cam:
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = WIDTH * TILE_SIZE
		cam.limit_bottom = HEIGHT * TILE_SIZE
