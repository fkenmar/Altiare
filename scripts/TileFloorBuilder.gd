extends RefCounted

## Builds a themed tile floor onto a TileMapLayer from PixelArt-generated tiles: an
## atlas of floor variants + an accent tile (flowers for town / rubble for dungeon) +
## a wall-border tile, painted with stable per-cell variation. Shared by town & dungeon.
## Preloaded by consumers (not class_name) so headless runs need no global class cache.

const PixelArt = preload("res://scripts/PixelArt.gd")

const FLOOR_VARIANTS: int = 3  # atlas indices 0..2 are plain floor
const ACCENT: int = 3          # flowers (town) / rubble (dungeon)
const WALL: int = 4
const ACCENT_CHANCE: float = 0.07

## theme: "town" or "dungeon". Generates the tileset, assigns it, and paints a
## width x height grid with a 1-tile wall border and varied interior floor.
static func build(ground: TileMapLayer, width: int, height: int, tile_size: int, theme: String) -> void:
	var tiles := PixelArt.ground_tiles(theme)  # [floor0, floor1, floor2, accent, wall]
	ground.tile_set = _atlas_tileset(tiles, tile_size)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9001 if theme == "town" else 9002
	for y in height:
		for x in width:
			var idx: int
			if x == 0 or y == 0 or x == width - 1 or y == height - 1:
				idx = WALL
			elif rng.randf() < ACCENT_CHANCE:
				idx = ACCENT
			else:
				idx = rng.randi_range(0, FLOOR_VARIANTS - 1)
			ground.set_cell(Vector2i(x, y), 0, Vector2i(idx, 0))

static func _atlas_tileset(tiles: Array, tile_size: int) -> TileSet:
	var count := tiles.size()
	var atlas := PixelArt.new_image(tile_size * count, tile_size)
	for i in count:
		atlas.blit_rect(tiles[i], Rect2i(0, 0, tile_size, tile_size), Vector2i(i * tile_size, 0))
	var source := TileSetAtlasSource.new()
	source.texture = PixelArt.tex(atlas)
	source.texture_region_size = Vector2i(tile_size, tile_size)
	for i in count:
		source.create_tile(Vector2i(i, 0))
	var ts := TileSet.new()
	ts.tile_size = Vector2i(tile_size, tile_size)
	ts.add_source(source, 0)
	return ts
