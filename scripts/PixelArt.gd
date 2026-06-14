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

# ============================================================================
# Characters & creatures (transparent sprites, outlined + shaded)
# ============================================================================

## A soft elliptical drop shadow (semi-transparent), placed under sprites at the feet.
static func shadow(w: int, h: int) -> ImageTexture:
	var img := new_image(w, h)
	var cx := w / 2.0
	var cy := h / 2.0
	for y in h:
		for x in w:
			var dx := (x - cx) / (w / 2.0)
			var dy := (y - cy) / (h / 2.0)
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, SHADOW)
	return tex(img)

## A 16x28 front-facing humanoid (player / villagers). Feet sit near the bottom.
static func character(skin: Color, hair: Color, shirt: Color, pants: Color) -> ImageTexture:
	var img := new_image(16, 28)
	var skin_dk := skin.darkened(0.12)
	var shirt_dk := shirt.darkened(0.18)
	# legs + boots
	rect(img, 5, 22, 2, 4, pants)
	rect(img, 9, 22, 2, 4, pants)
	rect(img, 4, 26, 3, 2, OUTLINE)
	rect(img, 9, 26, 3, 2, OUTLINE)
	# torso + arms + hands
	rect(img, 4, 13, 8, 10, shirt)
	rect(img, 10, 13, 2, 10, shirt_dk)  # shaded right side
	rect(img, 3, 14, 2, 6, shirt)
	rect(img, 11, 14, 2, 6, shirt_dk)
	rect(img, 3, 19, 2, 2, skin)
	rect(img, 11, 19, 2, 2, skin)
	# head
	rect(img, 5, 5, 6, 8, skin)
	rect(img, 10, 5, 1, 8, skin_dk)
	px(img, 6, 9, OUTLINE)  # eyes
	px(img, 9, 9, OUTLINE)
	# hair
	rect(img, 5, 2, 6, 1, hair)
	rect(img, 4, 3, 8, 3, hair)
	rect(img, 4, 5, 1, 3, hair)
	rect(img, 11, 5, 1, 3, hair)
	outline(img, OUTLINE)
	return tex(img)

## A monster blob keyed by kind (slime/goblin/brute) — cohesive and cute, Stardew-ish.
static func creature(kind: String) -> ImageTexture:
	match kind:
		"goblin":
			return _blob(Color8(122, 174, 92), 22, 17, true)
		"brute":
			return _blob(Color8(176, 74, 74), 28, 22, true)
		_:
			return _blob(Color8(142, 102, 192), 18, 14, false)

static func _blob(color: Color, w: int, h: int, angry: bool) -> ImageTexture:
	var img := new_image(w, h)
	var cx := w / 2.0
	var cy := h / 2.0
	var lt := color.lightened(0.28)
	var dk := color.darkened(0.22)
	for y in h:
		for x in w:
			var dx := (x - cx) / (w / 2.0 - 0.5)
			var dy := (y - cy) / (h / 2.0 - 0.5)
			if dx * dx + dy * dy <= 1.0:
				var c := color
				if y < h * 0.34:
					c = lt
				elif y > h * 0.78:
					c = dk
				img.set_pixel(x, y, c)
	disc(img, cx - 2, cy - h * 0.18, 1.6, lt)  # highlight
	var ey := int(cy + 1)
	var elx := int(cx - 4)
	var erx := int(cx + 2)
	rect(img, elx, ey, 2, 2, Color.WHITE)
	rect(img, erx, ey, 2, 2, Color.WHITE)
	px(img, elx + 1, ey + 1, OUTLINE)
	px(img, erx + 1, ey + 1, OUTLINE)
	if angry:
		px(img, elx - 1, ey - 1, OUTLINE)
		px(img, elx, ey - 1, OUTLINE)
		px(img, erx + 1, ey - 1, OUTLINE)
		px(img, erx + 2, ey - 1, OUTLINE)
	outline(img, OUTLINE)
	return tex(img)

# ============================================================================
# Props (buildings, furniture, the garden, signage, dungeon features)
# ============================================================================
const WOOD := Color8(150, 108, 66)
const WOOD_DK := Color8(112, 78, 48)
const ROOF := Color8(184, 84, 70)
const ROOF_DK := Color8(150, 62, 54)
const CREAM := Color8(224, 206, 170)
const CREAM_DK := Color8(196, 176, 142)
const GLASS := Color8(150, 200, 224)
const SOIL := Color8(122, 86, 58)
const SOIL_DK := Color8(96, 66, 44)
const STEM := Color8(96, 158, 70)
const LEAF := Color8(122, 188, 92)
const FRUIT := Color8(222, 96, 96)

static func house() -> ImageTexture:
	var w := 40
	var h := 44
	var img := new_image(w, h)
	rect(img, 4, 18, 32, 24, CREAM)
	rect(img, 31, 18, 5, 24, CREAM_DK)
	for i in range(0, 16):  # roof trapezoid, wide at the eaves
		var yy := 17 - i
		var half := 18 - i
		rect(img, 20 - half, yy, half * 2, 1, ROOF_DK if i < 2 else ROOF)
	rect(img, 17, 30, 7, 12, WOOD)   # door
	rect(img, 22, 30, 2, 12, WOOD_DK)
	px(img, 18, 36, Color8(240, 220, 120))
	rect(img, 8, 23, 7, 6, GLASS)    # window
	rect(img, 11, 23, 1, 6, CREAM_DK)
	rect(img, 8, 25, 7, 1, CREAM_DK)
	outline(img, OUTLINE)
	return tex(img)

static func bed() -> ImageTexture:
	var w := 40
	var h := 30
	var img := new_image(w, h)
	rect(img, 2, 2, w - 4, h - 4, WOOD)
	rect(img, 4, 4, w - 8, h - 8, Color8(236, 232, 224))
	rect(img, 5, 5, 12, h - 10, Color8(248, 246, 240))           # pillow
	rect(img, 18, 4, w - 22, h - 8, Color8(120, 150, 200))       # blanket
	rect(img, 18, 4, w - 22, 2, Color8(150, 176, 216))
	outline(img, OUTLINE)
	return tex(img)

static func cave() -> ImageTexture:
	var w := 40
	var h := 40
	var img := new_image(w, h)
	disc(img, 20, 24, 17, STONE_DK)
	disc(img, 20, 22, 16, STONE)
	disc(img, 10, 31, 4, STONE_DK)
	disc(img, 31, 31, 5, STONE_DK)
	disc(img, 14, 13, 2, STONE_LT)
	disc(img, 20, 27, 9, Color8(16, 12, 22))   # opening
	rect(img, 11, 27, 18, 11, Color8(16, 12, 22))
	outline(img, OUTLINE)
	return tex(img)

static func sign() -> ImageTexture:
	var w := 40
	var h := 40
	var img := new_image(w, h)
	rect(img, 8, 18, 3, 20, WOOD_DK)
	rect(img, 29, 18, 3, 20, WOOD_DK)
	rect(img, 5, 6, 30, 18, WOOD)
	rect(img, 5, 6, 30, 2, Color8(176, 130, 84))
	rect(img, 9, 9, 22, 12, Color8(238, 232, 214))  # paper
	for ly in [11, 14, 17]:
		rect(img, 11, ly, 16, 1, Color8(90, 80, 70))
	outline(img, OUTLINE)
	return tex(img)

static func tilled(stage: int) -> ImageTexture:
	var w := 40
	var h := 40
	var img := new_image(w, h)
	rect(img, 2, 2, w - 4, h - 4, SOIL_DK)  # dark earth base
	var rng := _rng(4242)
	for i in 70:                            # clumpy dirt mottling
		var cx := rng.randi_range(3, w - 5)
		var cy := rng.randi_range(3, h - 5)
		var c := SOIL if rng.randf() < 0.6 else SOIL.lightened(0.12)
		px(img, cx, cy, c)
		if rng.randf() < 0.5:
			px(img, cx + 1, cy, c)
	for ry in range(9, h - 6, 9):           # broken furrow dashes (tilled rows, not planks)
		var fx := 5
		while fx < w - 8:
			rect(img, fx, ry, 3, 1, SOIL.lightened(0.10))
			fx += rng.randi_range(6, 10)
	if stage == 1:
		for sx in [12, 20, 28]:
			px(img, sx, 26, STEM)
			px(img, sx, 25, LEAF)
	elif stage == 2:
		for sx in [12, 20, 28]:
			rect(img, sx, 18, 1, 8, STEM)
			px(img, sx - 1, 19, LEAF)
			px(img, sx + 1, 21, LEAF)
	elif stage == 3:
		for sx in [12, 20, 28]:
			rect(img, sx, 15, 1, 11, STEM)
			px(img, sx - 1, 17, LEAF)
			px(img, sx + 1, 19, LEAF)
			disc(img, sx, 14, 2, FRUIT)
	outline(img, OUTLINE)
	return tex(img)

static func stairs() -> ImageTexture:
	var w := 40
	var h := 40
	var img := new_image(w, h)
	var steps := 5
	for i in steps:
		var yy := 6 + i * 6
		var shade := STONE_LT.lerp(STONE_DK, float(i) / steps)
		rect(img, 6, yy, w - 12, 6, shade)
		rect(img, 6, yy, w - 12, 1, STONE_LT)
	rect(img, 12, 2, 16, 4, Color8(240, 236, 200))  # exit glow
	outline(img, OUTLINE)
	return tex(img)

# Decoration (non-interactive props that make the town feel lived-in)
static func tree() -> ImageTexture:
	var img := new_image(34, 44)
	rect(img, 15, 30, 4, 12, WOOD)        # trunk
	rect(img, 18, 30, 1, 12, WOOD_DK)
	disc(img, 17, 18, 13, HEDGE_DK)       # canopy
	disc(img, 17, 16, 12, HEDGE)
	disc(img, 13, 12, 6, HEDGE_LT)        # highlight
	outline(img, OUTLINE)
	return tex(img)

static func bush() -> ImageTexture:
	var img := new_image(26, 20)
	disc(img, 9, 12, 8, HEDGE_DK)
	disc(img, 17, 12, 8, HEDGE_DK)
	disc(img, 13, 10, 9, HEDGE)
	disc(img, 10, 7, 3, HEDGE_LT)
	outline(img, OUTLINE)
	return tex(img)

static func rock() -> ImageTexture:
	var img := new_image(22, 16)
	disc(img, 11, 11, 9, STONE_DK)
	disc(img, 11, 10, 8, STONE)
	disc(img, 8, 7, 3, STONE_LT)
	outline(img, OUTLINE)
	return tex(img)
