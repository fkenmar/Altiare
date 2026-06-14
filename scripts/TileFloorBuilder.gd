extends RefCounted

## Preloaded by consumers (e.g. `const TileFloorBuilder = preload(...)`) rather than
## referenced by class_name, so headless runs don't depend on the editor's global
## class cache (which lives in the gitignored .godot/).

## Builds a placeholder tile floor (floor fill + 1-tile wall border) onto a
## TileMapLayer from a code-generated 2-tile atlas, so we ship no art. Shared by the
## town and the dungeon — one home for the fiddly programmatic-TileSet generation.

const FLOOR_TILE := Vector2i(0, 0)
const WALL_TILE := Vector2i(1, 0)
const SOURCE_ID: int = 0

## Generate the tileset, assign it, and paint a width x height grid with a wall border.
static func build(ground: TileMapLayer, width: int, height: int, tile_size: int,
		floor_color: Color, wall_color: Color) -> void:
	ground.tile_set = _make_tileset(tile_size, floor_color, wall_color)
	for y in height:
		for x in width:
			var on_edge := x == 0 or y == 0 or x == width - 1 or y == height - 1
			ground.set_cell(Vector2i(x, y), SOURCE_ID, WALL_TILE if on_edge else FLOOR_TILE)

static func _make_tileset(tile_size: int, floor_color: Color, wall_color: Color) -> TileSet:
	var image := Image.create_empty(tile_size * 2, tile_size, false, Image.FORMAT_RGBA8)
	image.fill_rect(Rect2i(0, 0, tile_size, tile_size), floor_color)
	image.fill_rect(Rect2i(tile_size, 0, tile_size, tile_size), wall_color)

	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(image)
	source.texture_region_size = Vector2i(tile_size, tile_size)
	source.create_tile(FLOOR_TILE)
	source.create_tile(WALL_TILE)

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(tile_size, tile_size)
	tile_set.add_source(source, SOURCE_ID)
	return tile_set
