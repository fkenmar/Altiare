extends RefCounted

## Procedural pixel-art generator. Builds ImageTextures entirely in code (no external
## art files) with a cohesive earthy palette, clean outlines, and simple top-down
## shading — a big step toward a Stardew-ish look from flat placeholder squares.
## Preloaded by consumers (not class_name) so headless runs need no global class cache.
## All generation is deterministic (seeded), so the art never shimmers between runs.

# --- Cohesive palette ---
const OUTLINE := Color8(40, 34, 46)
const SHADOW := Color8(20, 18, 28, 90)

const GRASS := Color8(112, 170, 84)
const GRASS_DK := Color8(86, 142, 64)
const GRASS_LT := Color8(146, 200, 104)

const PATH := Color8(176, 140, 96)
const PATH_DK := Color8(146, 112, 74)

const HEDGE := Color8(74, 128, 64)
const HEDGE_DK := Color8(50, 96, 48)
const HEDGE_LT := Color8(104, 162, 84)

const STONE := Color8(110, 112, 126)
const STONE_DK := Color8(80, 82, 96)
const STONE_LT := Color8(142, 144, 158)

const DWALL := Color8(52, 50, 66)
const DWALL_DK := Color8(34, 32, 46)
const DWALL_LT := Color8(72, 70, 88)

const FLOWER_RED := Color8(220, 96, 96)
const FLOWER_YEL := Color8(244, 210, 102)
const FLOWER_WHT := Color8(238, 238, 230)
const FLOWER_CTR := Color8(244, 210, 102)

# ============================================================================
# Low-level drawing on an Image (FORMAT_RGBA8; create_empty => transparent)
# ============================================================================
static func new_image(w: int, h: int) -> Image:
	return Image.create_empty(w, h, false, Image.FORMAT_RGBA8)

static func px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)

static func rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			px(img, xx, yy, c)

static func disc(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	var r2 := r * r
	for yy in range(int(cy - r), int(cy + r) + 1):
		for xx in range(int(cx - r), int(cx + r) + 1):
			var dx := xx - cx
			var dy := yy - cy
			if dx * dx + dy * dy <= r2:
				px(img, xx, yy, c)

## Add a 1px outline of `color` around every opaque pixel (huge readability boost).
static func outline(img: Image, color: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var solid := []
	for y in h:
		var row := []
		for x in w:
			row.append(img.get_pixel(x, y).a > 0.5)
		solid.append(row)
	for y in h:
		for x in w:
			if solid[y][x]:
				continue
			var near := false
			for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
				var nx: int = x + d[0]
				var ny: int = y + d[1]
				if nx >= 0 and ny >= 0 and nx < w and ny < h and solid[ny][nx]:
					near = true
					break
			if near:
				img.set_pixel(x, y, color)

static func tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)

static func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r

# ============================================================================
# Ground tiles (returned as an Array of 32x32 Images: [floor0,floor1,floor2,accent,wall])
# ============================================================================
static func ground_tiles(theme: String) -> Array:
	if theme == "dungeon":
		return [_stone(0), _stone(1), _stone(2), _rubble(), _dungeon_wall()]
	return [_grass(0), _grass(1), _grass(2), _grass_flowers(), _hedge()]

static func _base_noise(s: int, seed_id: int, base: Color, dk: Color, lt: Color, density: int) -> Image:
	var img := new_image(s, s)
	rect(img, 0, 0, s, s, base)
	var rng := _rng(seed_id)
	for i in density:
		var x := rng.randi_range(0, s - 1)
		var y := rng.randi_range(0, s - 1)
		px(img, x, y, dk if (i % 2 == 0) else lt)
	return img

static func _grass(variant: int) -> Image:
	var s := 32
	var img := _base_noise(s, 1100 + variant, GRASS, GRASS_DK, GRASS_LT, 34)
	# short vertical blades
	var rng := _rng(1200 + variant)
	for i in 14:
		var x := rng.randi_range(1, s - 2)
		var y := rng.randi_range(2, s - 3)
		var c := GRASS_DK if (i % 2 == 0) else GRASS_LT
		px(img, x, y, c)
		px(img, x, y + 1, c)
	return img

static func _grass_flowers() -> Image:
	var img := _grass(3)
	var rng := _rng(1300)
	var palette := [FLOWER_RED, FLOWER_YEL, FLOWER_WHT]
	for i in 3:
		var cx := rng.randi_range(5, 26)
		var cy := rng.randi_range(5, 26)
		var col: Color = palette[i % palette.size()]
		# 4-petal flower with a centre
		px(img, cx, cy - 1, col)
		px(img, cx, cy + 1, col)
		px(img, cx - 1, cy, col)
		px(img, cx + 1, cy, col)
		px(img, cx, cy, FLOWER_CTR)
	return img

static func _hedge() -> Image:
	var s := 32
	var img := new_image(s, s)
	rect(img, 0, 0, s, s, HEDGE)
	# leafy dabs, lighter toward the top
	var rng := _rng(1400)
	for i in 90:
		var x := rng.randi_range(0, s - 1)
		var y := rng.randi_range(0, s - 1)
		var c := HEDGE_LT if y < 16 else HEDGE_DK
		if rng.randf() < 0.5:
			px(img, x, y, c)
	rect(img, 0, s - 4, s, 4, HEDGE_DK)  # shaded base
	rect(img, 0, 0, s, 2, HEDGE_LT)      # lit crown
	return img

static func _stone(variant: int) -> Image:
	var s := 32
	var img := _base_noise(s, 2100 + variant, STONE, STONE_DK, STONE_LT, 26)
	# faint grout lines for a flagstone feel
	for x in s:
		px(img, x, 0, STONE_DK)
	for y in s:
		px(img, 0, y, STONE_DK)
	return img

static func _rubble() -> Image:
	var img := _stone(3)
	var rng := _rng(2300)
	for i in 4:
		var cx := rng.randi_range(6, 25)
		var cy := rng.randi_range(6, 25)
		disc(img, cx, cy, 2.0, STONE_DK)
		px(img, cx - 1, cy - 1, STONE_LT)
	return img

static func _dungeon_wall() -> Image:
	var s := 32
	var img := new_image(s, s)
	rect(img, 0, 0, s, s, DWALL)
	# brick courses
	for y in range(0, s, 8):
		rect(img, 0, y, s, 1, DWALL_DK)
	for y in range(0, s, 16):
		for x in range(0, s, 16):
			px(img, x, y + 4, DWALL_DK)
	for x in range(8, s, 16):
		rect(img, x, 0, 1, 8, DWALL_DK)
	for x in range(0, s, 16):
		rect(img, x, 8, 1, 8, DWALL_DK)
	rect(img, 0, 0, s, 1, DWALL_LT)  # faint top highlight
	return img
