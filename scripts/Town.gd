extends Node2D

## The town: a TileMapLayer floor built in code from a generated placeholder tileset
## (no art shipped — see CLAUDE.md), plus a StaticBody2D wall border in the scene so
## the player is bounded. Collision lives on the StaticBody2D, not the tiles — the
## simplest thing that gives us "bump the walls" without authoring a tile physics layer.

const TILE_SIZE: int = 32
const WIDTH: int = 20   # tiles wide
const HEIGHT: int = 15  # tiles tall

# Atlas coordinates of the two generated placeholder tiles.
const FLOOR_TILE := Vector2i(0, 0)
const WALL_TILE := Vector2i(1, 0)
const SOURCE_ID: int = 0

@onready var _ground: TileMapLayer = $Ground

func _ready() -> void:
	_ground.tile_set = _build_tileset()
	_paint_town()

## Build a 2-tile placeholder TileSet (floor + wall) from a tiny generated atlas
## image so the project ships no art: green floor tile, brown wall tile.
func _build_tileset() -> TileSet:
	var image := Image.create_empty(TILE_SIZE * 2, TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill_rect(Rect2i(0, 0, TILE_SIZE, TILE_SIZE), Color(0.25, 0.5, 0.28))           # floor
	image.fill_rect(Rect2i(TILE_SIZE, 0, TILE_SIZE, TILE_SIZE), Color(0.36, 0.27, 0.18)) # wall
	var texture := ImageTexture.create_from_image(image)

	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	source.create_tile(FLOOR_TILE)
	source.create_tile(WALL_TILE)

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_source(source, SOURCE_ID)
	return tile_set

## Fill the floor and draw a 1-tile wall border (purely visual; see note above).
func _paint_town() -> void:
	for y in HEIGHT:
		for x in WIDTH:
			var on_edge := x == 0 or y == 0 or x == WIDTH - 1 or y == HEIGHT - 1
			var atlas := WALL_TILE if on_edge else FLOOR_TILE
			_ground.set_cell(Vector2i(x, y), SOURCE_ID, atlas)
