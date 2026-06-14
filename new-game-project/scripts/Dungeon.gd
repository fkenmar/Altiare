extends Node2D

## The dungeon floor. Builds its (darker) tile floor via the shared TileFloorBuilder;
## walls, the exit stairs, the player spawn, and monsters are placed in Dungeon.tscn.
## Listens for GameState.player_fainted to drag the player back to town.

const TileFloorBuilder = preload("res://scripts/TileFloorBuilder.gd")

const TILE_SIZE: int = 32
const WIDTH: int = 16
const HEIGHT: int = 12

const SCALING_PER_LEVEL: float = 0.3  # monsters get +30% per player level beyond 1

var _returning: bool = false

@onready var _ground: TileMapLayer = $Ground

func _ready() -> void:
	TileFloorBuilder.build(_ground, WIDTH, HEIGHT, TILE_SIZE, "dungeon")
	GameState.player_fainted.connect(_on_player_fainted)
	_scale_monsters()
	_clamp_camera()

## Clamp the player's camera to the dungeon bounds so the zoom never shows the void.
func _clamp_camera() -> void:
	var cam := get_node_or_null("Player/Camera2D") as Camera2D
	if cam:
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = WIDTH * TILE_SIZE
		cam.limit_bottom = HEIGHT * TILE_SIZE

## Each dive (the scene is freshly reloaded, so monsters respawn) scales to the player's
## level, keeping the dungeon a meaningful reason to descend on day 10 as on day 1.
func _scale_monsters() -> void:
	var factor := 1.0 + SCALING_PER_LEVEL * (GameState.level - 1)
	for m in get_tree().get_nodes_in_group("monster"):
		m.apply_scaling(factor)

func _on_player_fainted() -> void:
	# Re-assert a survivable floor on EVERY faint, BEFORE the guard, so a second
	# same-frame killing blow can't undo it (you arrive home barely conscious, not dead).
	GameState.hp = max(GameState.hp, 1)
	if _returning:
		return  # one faint, one trip home (multiple monsters can zero us in a frame)
	_returning = true
	print("You fainted! Dragged back to town.")
	get_tree().change_scene_to_file("res://scenes/World.tscn")
